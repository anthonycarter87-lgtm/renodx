// FS25 XeGTAO main pass (3 slices x 3 steps in the game), hand-decompiled from the DXIL (the automatic decompiler can't handle
// its loops). Follows Intel's XeGTAO MainPass, with FS25's own additions kept: depth edges are loaded rather than
// gathered, samples that land off-screen are ignored, and AO fades out very close to the camera.
// RenoDX: AO Radius scales the game's effect radius; AO Quality raises slices x steps (4x4, 6x6) so wide radii
// aren't sampled too sparsely.
#include "./shared.h"

Texture2D<uint> g_srcHilbertLUT : register(t0);
Texture2D<float4> g_srcNormalmap : register(t1);
Texture2D<float> g_srcWorkingDepth : register(t2);
RWTexture2D<uint> g_outWorkingAOTerm : register(u0);
RWTexture2D<float> g_outWorkingEdges : register(u1);

cbuffer GTAOParams : register(b0) {
  float2 gCst_iViewportSize : packoffset(c000.x);
  float2 gCst_ViewportPixelSize : packoffset(c000.z);
  float2 gCst_DepthUnpackConsts : packoffset(c001.x);
  float2 gCst_CameraTanHalfFOV : packoffset(c001.z);
  float2 gCst_NDCToViewMul : packoffset(c002.x);
  float2 gCst_NDCToViewAdd : packoffset(c002.z);
  float2 gCst_NDCToViewMul_x_PixelSize : packoffset(c003.x);
  float gCst_EffectRadius : packoffset(c003.z);
  float gCst_EffectFalloffRange : packoffset(c003.w);
  float gCst_RadiusMultiplier : packoffset(c004.x);
  float gCst_iMipOffset : packoffset(c004.y);
  float gCst_FinalValuePower : packoffset(c004.z);
  float gCst_DenoiseBlurBeta : packoffset(c004.w);
  float gCst_SampleDistributionPower : packoffset(c005.x);
  float gCst_ThinOccluderCompensation : packoffset(c005.y);
  float gCst_DepthMIPSamplingOffset : packoffset(c005.z);
  float gCst_iNoiseIndex : packoffset(c005.w);
  float gCst_farNDCz : packoffset(c006.x);
  float gCst_msaaSampleCount : packoffset(c006.y);
};

cbuffer GTAOTemporalParams : register(b1) {
  row_major float4x4 g_reProjection : packoffset(c000.x);
  float g_nearClip : packoffset(c004.x);
  float g_iNormalMapScale : packoffset(c004.y);
  float g_iNumSamples : packoffset(c004.z);
};

SamplerState samplerPointClamp : register(s0);

static const float RADIUS_MULTIPLIER = 1.457f;
static const float FALLOFF_RANGE = 0.615f;  // baked into the game's shader; the cbuffer value is used for falloffFrom
static const float PIXEL_TOO_CLOSE_THRESHOLD = 1.3f;
static const float NEAR_FADE_RADIUS_SCALE = 0.7285f;

// XeGTAO_FastACos with FS25's exact constants (and its fast sqrt).
float FastACos(float x) {
  const float abs_x = abs(x);
  float result = asfloat(0x3FC90FD8u) - 0.1565829962491989f * abs_x;
  result *= asfloat(0x1FBD1DF5 + (asint(1.f - abs_x) >> 1));
  return (x >= 0.f) ? result : (asfloat(0x40490FDCu) - result);
}

float3 ScreenToViewPosition(float2 screen_uv, float view_z) {
  return float3((gCst_NDCToViewMul * screen_uv + gCst_NDCToViewAdd) * view_z, view_z);
}

[numthreads(8, 8, 1)]
void main(uint3 SV_DispatchThreadID: SV_DispatchThreadID) {
  const uint2 pixel = SV_DispatchThreadID.xy;
  const int depth_mip = asint(gCst_iMipOffset);

  // Spatio-temporal noise from the Hilbert LUT.
  const uint hilbert_index = g_srcHilbertLUT.Load(int3(pixel & 63u, 0)).x + 288u * (asuint(gCst_iNoiseIndex) & 63u);
  const float2 noise = frac(0.5f + float(hilbert_index) * float2(0.7548776865005493f, 0.5698403120040894f));

  const int normal_scale = asint(g_iNormalMapScale);
  const float3 normal_sample = g_srcNormalmap.Load(int3(normal_scale * pixel, 0)).xyz;
  const float3 view_normal = float3(normal_sample.x, normal_sample.y, -normal_sample.z);

  const float2 pixel_center = float2(pixel) + 0.5f;
  const float2 screen_uv = gCst_ViewportPixelSize * pixel_center;

  // Depth edges (FS25 loads the 2x2 neighbourhood instead of gathering).
  const uint x_minus = (pixel.x != 0u) ? (pixel.x - 1u) : 0u;
  const uint y_minus = (pixel.y != 0u) ? (pixel.y - 1u) : 0u;
  const uint x_center = x_minus + 1u;
  const uint y_center = y_minus + 1u;
  const uint x_safe = (pixel.x != 0xFFFFFFFFu) ? pixel.x : 0u;
  const uint y_safe = (pixel.y != 0xFFFFFFFFu) ? pixel.y : 0u;
  const float depth_top = g_srcWorkingDepth.Load(int3(x_center, y_minus, depth_mip));
  const float depth_left = g_srcWorkingDepth.Load(int3(x_minus, y_center, depth_mip));
  const float depth_center = g_srcWorkingDepth.Load(int3(x_center, y_center, depth_mip));
  const float depth_right = g_srcWorkingDepth.Load(int3(x_safe + 1u, y_safe, depth_mip));
  const float depth_bottom = g_srcWorkingDepth.Load(int3(x_safe, y_safe + 1u, depth_mip));

  const float4 edges = float4(depth_left, depth_right, depth_top, depth_bottom) - depth_center;
  const float slope_lr = (depth_right - depth_left) * 0.5f;
  const float slope_tb = (depth_bottom - depth_top) * 0.5f;
  const float4 edges_slope_adjusted = edges + float4(slope_lr, -slope_lr, slope_tb, -slope_tb);
  float4 edges_lrtb = min(abs(edges), abs(edges_slope_adjusted));
  edges_lrtb = saturate(1.25f - edges_lrtb / (depth_center * 0.010999999940395355f));
  edges_lrtb = round(saturate(edges_lrtb) * 2.9000000953674316f);
  g_outWorkingEdges[pixel] = dot(edges_lrtb, float4(64.f / 255.f, 16.f / 255.f, 4.f / 255.f, 1.f / 255.f));

  const float view_z = depth_center * 0.9999899864196777f;
  const float3 center_position = ScreenToViewPosition(screen_uv, view_z);
  const float3 view_vec = normalize(-center_position);

  const float game_radius = gCst_EffectRadius;
  const float effect_radius = game_radius * CUSTOM_AO_RADIUS * RADIUS_MULTIPLIER;
  const float falloff_range = effect_radius * FALLOFF_RANGE;
  const float falloff_from = effect_radius * (1.f - gCst_EffectFalloffRange);
  const float falloff_mul = -1.f / falloff_range;
  const float falloff_add = falloff_from / falloff_range + 1.f;

  const float screenspace_radius = effect_radius / (view_z * gCst_NDCToViewMul_x_PixelSize.x);
  float visibility = saturate((10.f - screenspace_radius) * 0.01f) * 0.5f;

  // FS25 skips AO right at the camera; keep that tied to the game's own radius.
  const float near_fade_start = game_radius * NEAR_FADE_RADIUS_SCALE;
  if (view_z < near_fade_start || screenspace_radius < PIXEL_TOO_CLOSE_THRESHOLD) {
    g_outWorkingAOTerm[pixel] = 255u;
    return;
  }

  const float min_s = PIXEL_TOO_CLOSE_THRESHOLD / screenspace_radius;
  const int slice_count = (CUSTOM_AO_QUALITY >= 2.f) ? 6 : ((CUSTOM_AO_QUALITY >= 1.f) ? 4 : 3);
  const int steps_per_slice = slice_count;
  const float slice_count_f = float(slice_count);
  const float steps_per_slice_f = float(steps_per_slice);

  [loop]
  for (int slice = 0; slice < slice_count; ++slice) {
    const float slice_f = float(slice);
    const float phi = (slice_f + noise.x) * (3.1415927f / slice_count_f);
    const float cos_phi = cos(phi);
    const float sin_phi = sin(phi);
    const float2 omega = float2(cos_phi, -sin_phi) * screenspace_radius;

    const float3 direction_vec = float3(cos_phi, sin_phi, 0.f);
    const float3 ortho_direction_vec = direction_vec - dot(direction_vec, view_vec) * view_vec;
    const float3 axis_vec = normalize(cross(ortho_direction_vec, view_vec));
    const float3 projected_normal = view_normal - axis_vec * dot(view_normal, axis_vec);

    const float sign_norm = sign(dot(ortho_direction_vec, projected_normal));
    const float projected_normal_length = length(projected_normal);
    const float cos_norm = saturate(dot(projected_normal, view_vec) / projected_normal_length);
    const float n = sign_norm * FastACos(cos_norm);

    const float low_horizon_cos0 = cos(n + 1.5707963705062866f);
    const float low_horizon_cos1 = cos(n - 1.5707963705062866f);
    float horizon_cos0 = low_horizon_cos0;
    float horizon_cos1 = low_horizon_cos1;

    [loop]
    for (int step = 0; step < steps_per_slice; ++step) {
      const float step_f = float(step);
      const float step_noise = frac((step_f * steps_per_slice_f + slice_f) * 0.6180340051651001f + noise.y);
      float s = (step_f + step_noise) / steps_per_slice_f;
      s = s * s + min_s;

      const float2 sample_offset = s * omega;
      const float mip_level = min(max(log2(length(sample_offset)) - gCst_DepthMIPSamplingOffset, 0.f), 5.f)
                              + float(depth_mip);
      const float2 rounded_offset = round(sample_offset);

      const float2 sample_uv0 = (rounded_offset + pixel_center) * gCst_ViewportPixelSize;
      const float2 sample_uv1 = (pixel_center - rounded_offset) * gCst_ViewportPixelSize;
      const float sample_z0 = g_srcWorkingDepth.SampleLevel(samplerPointClamp, sample_uv0, mip_level);
      const float sample_z1 = g_srcWorkingDepth.SampleLevel(samplerPointClamp, sample_uv1, mip_level);

      const float3 sample_delta0 = ScreenToViewPosition(sample_uv0, sample_z0) - center_position;
      const float3 sample_delta1 = ScreenToViewPosition(sample_uv1, sample_z1) - center_position;
      const float sample_dist0 = length(sample_delta0);
      const float sample_dist1 = length(sample_delta1);

      // FS25: samples outside the screen don't occlude.
      const float weight0 = all(sample_uv0 == saturate(sample_uv0)) ? saturate(sample_dist0 * falloff_mul + falloff_add) : 0.f;
      const float weight1 = all(sample_uv1 == saturate(sample_uv1)) ? saturate(sample_dist1 * falloff_mul + falloff_add) : 0.f;

      const float shc0 = lerp(low_horizon_cos0, dot(sample_delta0 / sample_dist0, view_vec), weight0);
      const float shc1 = lerp(low_horizon_cos1, dot(sample_delta1 / sample_dist1, view_vec), weight1);
      horizon_cos0 = max(horizon_cos0, shc0);
      horizon_cos1 = max(horizon_cos1, shc1);
    }

    const float length_adjusted = lerp(projected_normal_length, 1.f, 0.05f);
    const float h0 = -FastACos(horizon_cos1);
    const float h1 = FastACos(horizon_cos0);
    const float arcs = 2.f * cos_norm + (2.f * h0 + 2.f * h1) * sin(n) - cos(2.f * h0 - n) - cos(2.f * h1 - n);
    visibility += length_adjusted * 0.25f * arcs;
  }

  visibility = exp2(log2(visibility / slice_count_f) * gCst_FinalValuePower);
  visibility = lerp(1.f, visibility, saturate((view_z - near_fade_start) / near_fade_start));
  visibility = saturate(max(0.029999999329447746f, visibility));
  g_outWorkingAOTerm[pixel] = uint(visibility * 255.f + 0.5f);
}
