// FS25 final HDR composite: scene + bloom -> eye adaptation -> PQ-indexed grading LUT -> UI overlay -> HDR10 PQ.
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
    const float3 vanilla_scene_nits = (scene_sample.rgb + g_bloomMagnitude * bloom_sample)
                                      * (scene_mask * eye_exposure * g_sceneNits);
    const float3 vanilla_lut_coords = renodx::color::pq::Encode(vanilla_scene_nits, 1.f) * 0.96875f + 0.015625f;
    const float3 vanilla_graded = colorLUT.Sample(samplerBilinearClamp, vanilla_lut_coords) * 1.05f;
    const float3 vanilla_ui_nits = max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * g_overlayNits));
    const float3 vanilla_composite = vanilla_ui_nits + vanilla_graded * overlay.a * g_sceneNits;
    float3 vanilla_output_nits;
    [unroll]
    for (int channel = 0; channel < 3; ++channel) {
      vanilla_output_nits[channel] = ApplyGameDisplayCurve(vanilla_composite[channel], 168.f, 100.f);
    }
    return float4(renodx::color::pq::Encode(vanilla_output_nits, 1.f), output_alpha);
  }

  const float scene_nits = FS25_SCENE_NITS(g_sceneNits);
  const float ui_nits = FS25_UI_NITS(g_overlayNits);
  const float peak_nits = FS25_PEAK_NITS(g_screenMaxNits);

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

  // The LUT holds the game's colour grading plus its BT.2390 roll-off to the peak, output in BT.2020.
  const float3 lut_coords = renodx::color::pq::EncodeSafe(scene_relative, scene_nits) * 0.96875f + 0.015625f;
  const float3 graded_scene_nits = colorLUT.Sample(samplerBilinearClamp, lut_coords) * 1.05f * scene_nits * overlay.a;
  const float3 ui_bt2020_nits = max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * ui_nits));

  // Game settings keep FS25's own curve anchor (168 nits in -> 100 nits out) so the default look matches what
  // was tuned in testing. Custom brightness anchors the curve at the chosen game brightness so the slider is
  // the real diffuse white in nits.
  const float curve_reference_nits = FS25_USE_CUSTOM_BRIGHTNESS ? scene_nits : 168.f;
  const float curve_white_nits = FS25_USE_CUSTOM_BRIGHTNESS ? scene_nits : 100.f;

  const float scene_y = renodx::color::y::from::BT2020(graded_scene_nits);
  float scene_y_out = ApplyGameDisplayCurve(scene_y, curve_reference_nits, curve_white_nits);
  // Above diffuse white, ease back out of the curve so highlights reach the display peak instead of being squashed.
  const float highlight_blend = smoothstep(curve_reference_nits, max(peak_nits, curve_reference_nits + 1.f), scene_y);
  scene_y_out = lerp(scene_y_out, min(scene_y, peak_nits), highlight_blend);
  float3 scene_out_nits = graded_scene_nits * renodx::math::DivideSafe(scene_y_out, scene_y, 0.f);

  const float scene_y_final = renodx::color::y::from::BT2020(scene_out_nits);
  const float peak_fraction = saturate(scene_y_final / peak_nits);
  scene_out_nits = scene_y_final + (scene_out_nits - scene_y_final) * lerp(1.f, RENODX_TONE_MAP_HIGHLIGHT_SATURATION, peak_fraction);
  scene_out_nits = lerp(scene_out_nits, scene_y_final.xxx, RENODX_TONE_MAP_BLOWOUT * peak_fraction * peak_fraction);

  float3 ui_out_nits = ui_bt2020_nits;
  if (!FS25_USE_CUSTOM_BRIGHTNESS) {
    const float ui_y = renodx::color::y::from::BT2020(ui_bt2020_nits);
    ui_out_nits *= renodx::math::DivideSafe(ApplyGameDisplayCurve(ui_y, 168.f, 100.f), ui_y, 0.f);
  }

  return float4(renodx::color::pq::EncodeSafe(scene_out_nits + ui_out_nits, 1.f), output_alpha);
}
