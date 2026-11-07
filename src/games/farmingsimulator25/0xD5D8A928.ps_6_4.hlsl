// FS25 final HDR composite: scene + bloom -> eye adaptation -> PQ-indexed grading LUT -> UI overlay -> HDR10 PQ.
// The LUT builder (0xE1DE1ABE) is modified to hold only colour grading, so this shader recreates FS25's HDR Contrast
// and BT.2390 roll-off for Vanilla, and replaces them with RenoDX tone mapping otherwise.
#include "./shared.h"

Texture2D<float4> sceneTexture : register(t0);

Texture2D<float3> bloomMaskTexture : register(t1);

StructuredBuffer<float> eyeAdaptedLuminanceBuffer : register(t2);

Texture3D<float3> colorLUT : register(t3);

Texture2D<float4> overlayTexture : register(t4);

cbuffer DeviceParameters : register(b0) {
  float4 g_sceneClipViewport : packoffset(c000.x);
  float g_screenMinNits : packoffset(c001.x);
  float g_screenMaxNits : packoffset(c001.y);
  float g_sceneNits : packoffset(c001.z);
  float g_overlayNits : packoffset(c001.w);
  float g_hdrGamma : packoffset(c002.x);
};

cbuffer BloomParams : register(b1) {
  float g_bloomThreshold : packoffset(c000.x);
  float g_bloomMagnitude : packoffset(c000.y);
  float g_linearExposure : packoffset(c000.z);
  float g_middleGrayValue : packoffset(c000.w);
};

SamplerState samplerBilinearClamp : register(s0);

// The game's final curve: BT.709 camera OETF followed by a 2.4 display gamma, which adds contrast.
// Vanilla runs it per channel on the BT.2020 composite (oversaturating); RenoDX runs it on luminance.
float ApplyGameDisplayCurve(float y_nits, float reference_nits, float white_nits) {
  const float y_relative = y_nits / reference_nits;
  const float encoded = (y_relative <= 0.018f) ? (4.5f * y_relative) : (1.099f * pow(y_relative, 0.45f) - 0.099f);
  return white_nits * pow(max(encoded, 0.f), 2.4f);
}

float3 SampleGradingLUT(float3 scene_relative) {
  const float3 lut_coords = renodx::color::pq::EncodeSafe(scene_relative, g_sceneNits) * 0.96875f + 0.015625f;
  return colorLUT.Sample(samplerBilinearClamp, lut_coords) * 1.05f;
}

float4 main(
    noperspective float4 SV_Position: SV_Position,
    linear float2 TEXCOORD: TEXCOORD)
    : SV_Target {
  const float2 scene_uv = (TEXCOORD - g_sceneClipViewport.xy) / g_sceneClipViewport.zw;
  const float scene_mask = float(all(scene_uv > 0.f) && all(scene_uv < 1.f));

  const float4 scene_sample = sceneTexture.Sample(samplerBilinearClamp, scene_uv);
  const float3 bloom_sample = bloomMaskTexture.Sample(samplerBilinearClamp, scene_uv);
  const float eye_exposure = g_middleGrayValue / eyeAdaptedLuminanceBuffer[0];
  const float4 overlay = overlayTexture.Sample(samplerBilinearClamp, TEXCOORD);
  const float output_alpha = scene_sample.a * scene_mask;

  [branch]
  if (RENODX_TONE_MAP_TYPE == 0.f) {
    // FS25's HDR Contrast, exactly as its LUT builder applies it (per channel, pivoted at diffuse white).
    float3 vanilla_scene_relative = (scene_sample.rgb + g_bloomMagnitude * bloom_sample) * (scene_mask * eye_exposure);
    if (g_hdrGamma >= 1.f) {
      vanilla_scene_relative = pow(abs(vanilla_scene_relative), g_hdrGamma);
    } else {
      const float3 gamma_weight = saturate(pow(2.f - vanilla_scene_relative, 3.f));
      vanilla_scene_relative = pow(abs(vanilla_scene_relative), g_hdrGamma) * gamma_weight
                               + (1.f - gamma_weight) * vanilla_scene_relative;
    }

    // The LUT stores M * graded; FS25 applies its BT.2390 roll-off before M, so undo M, roll off, then reapply it.
    const float3x3 LUT_OUTPUT_MATRIX = float3x3(
        1.0258320569992065f, -0.02005285769701004f, -0.005771368741989136f,
        -0.0022350086364895105f, 1.004569172859192f, -0.0023525916039943695f,
        -0.005014397669583559f, -0.0252938661724329f, 1.0304558277130127f);
    const float3x3 LUT_OUTPUT_MATRIX_INVERSE = float3x3(
        0.9748880441f, 0.0195989801f, 0.0055048908f,
        0.0021802080f, 0.9955526666f, 0.0022851165f,
        0.0047975101f, 0.0245324955f, 0.9705271941f);
    const float3 graded_nits = max(0.f, mul(LUT_OUTPUT_MATRIX_INVERSE, SampleGradingLUT(vanilla_scene_relative))) * g_sceneNits;

    static const float PQ_ZERO = 7.309558895940427e-07f;
    const float target_min = (renodx::color::pq::Encode(g_screenMinNits, 1.f) - PQ_ZERO) * 1.0000007152557373f;
    const float target_max = (renodx::color::pq::Encode(g_screenMaxNits, 1.f) - PQ_ZERO) * 1.0000007152557373f;
    const float knee_start = target_max * 1.500001072883606f - 0.5f;
    const float3 source = saturate((renodx::color::pq::Encode(graded_nits, 1.f) - PQ_ZERO) * 0.9999992847442627f);
    const float3 t = (source - knee_start) / (1.f - knee_start);
    const float3 t2 = t * t;
    const float3 t3 = t2 * t;
    const float3 spline = (2.f * t3 - 3.f * t2 + 1.f) * knee_start + (t3 - 2.f * t2 + t) * (1.f - knee_start)
                          + (3.f * t2 - 2.f * t3) * target_max;
    float3 rolled_off = saturate(select(source < knee_start, source, spline));
    rolled_off += pow(1.f - rolled_off, 4.f) * target_min;
    const float3 rolled_off_nits = renodx::color::pq::Decode(rolled_off * 0.9999992847442627f + PQ_ZERO, 1.f);
    const float3 vanilla_graded = max(0.f, mul(LUT_OUTPUT_MATRIX, rolled_off_nits));

    const float3 vanilla_ui_nits = max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * g_overlayNits));
    const float3 vanilla_composite = vanilla_ui_nits + vanilla_graded * overlay.a;
    float3 vanilla_output_nits;
    [unroll]
    for (int channel = 0; channel < 3; ++channel) {
      vanilla_output_nits[channel] = ApplyGameDisplayCurve(vanilla_composite[channel], 168.f, 100.f);
    }
    return float4(renodx::color::pq::Encode(vanilla_output_nits, 1.f), output_alpha);
  }

  const float scene_nits = RENODX_DIFFUSE_WHITE_NITS;
  const float peak_nits = RENODX_PEAK_WHITE_NITS;

  // BT.709 linear, 1.0 = game brightness (diffuse white).
  float3 scene_relative = (scene_sample.rgb + g_bloomMagnitude * CUSTOM_BLOOM * bloom_sample)
                          * (scene_mask * eye_exposure);
  scene_relative = renodx::color::grade::UserColorGrading(
      scene_relative,
      RENODX_TONE_MAP_EXPOSURE,
      RENODX_TONE_MAP_HIGHLIGHTS,
      RENODX_TONE_MAP_SHADOWS,
      RENODX_TONE_MAP_CONTRAST,
      RENODX_TONE_MAP_SATURATION,
      0.f,
      0.f);

  // The LUT holds only the game's colour grading, output in BT.2020 relative to diffuse white.
  const float3 graded_relative = lerp(
                                     renodx::color::bt2020::from::BT709(scene_relative),
                                     SampleGradingLUT(scene_relative),
                                     RENODX_COLOR_GRADE_STRENGTH)
                                 * overlay.a;
  const float3 ui_bt2020_nits = max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * RENODX_GRAPHICS_WHITE_NITS));

  // FS25's display curve (its shape at HDR 3D Brightness 410) applied on luminance and normalised so mid-grey stays
  // at 18% of Game Brightness, matching how brightness behaves in other RenoDX mods.
  const float curve_reference = 168.f / 410.f;
  const float mid_gray_scale = 0.18f / ApplyGameDisplayCurve(0.18f, curve_reference, 1.f);
  const float graded_y = renodx::color::y::from::BT2020(graded_relative);
  const float curved_y_nits = ApplyGameDisplayCurve(graded_y, curve_reference, mid_gray_scale) * scene_nits;

  // Highlights stay linear up to half the peak, then roll off smoothly to the peak.
  const float knee_nits = 0.5f * peak_nits;
  const float tonemapped_y_nits = (curved_y_nits <= knee_nits)
                                      ? curved_y_nits
                                      : (knee_nits + renodx::tonemap::Neutwo(curved_y_nits - knee_nits, peak_nits - knee_nits));
  float3 scene_out_nits = graded_relative * renodx::math::DivideSafe(tonemapped_y_nits, graded_y, 0.f);

  const float scene_y_final = renodx::color::y::from::BT2020(scene_out_nits);
  const float peak_fraction = saturate(scene_y_final / peak_nits);
  scene_out_nits = scene_y_final + (scene_out_nits - scene_y_final) * lerp(1.f, RENODX_TONE_MAP_HIGHLIGHT_SATURATION, peak_fraction);
  scene_out_nits = lerp(scene_out_nits, scene_y_final.xxx, RENODX_TONE_MAP_BLOWOUT * peak_fraction * peak_fraction);

  return float4(renodx::color::pq::EncodeSafe(scene_out_nits + ui_bt2020_nits, 1.f), output_alpha);
}
