// FS25 menu composite: menu background scene + UI overlay -> HDR10 PQ (no grading LUT or bloom).
// Vanilla uses FS25's HDR Calibration values; RenoDX uses the same tone map and brightness sliders as gameplay.
#include "./common.hlsli"

Texture2D<float3> sceneTexture : register(t0);

Texture2D<float4> overlayTexture : register(t1);

cbuffer DeviceParameters : register(b0) {
  float4 g_sceneClipViewport : packoffset(c000.x);
  float g_screenMinNits : packoffset(c001.x);
  float g_screenMaxNits : packoffset(c001.y);
  float g_sceneNits : packoffset(c001.z);
  float g_overlayNits : packoffset(c001.w);
  float g_hdrGamma : packoffset(c002.x);
};

SamplerState sceneSampler : register(s0);

SamplerState overlaySampler : register(s1);

float4 main(
    noperspective float4 SV_Position: SV_Position,
    linear float2 TEXCOORD: TEXCOORD)
    : SV_Target {
  float3 scene = sceneTexture.Sample(sceneSampler, TEXCOORD);
  const float4 overlay = overlayTexture.Sample(overlaySampler, TEXCOORD);
  const float output_alpha = 1.f - overlay.a;

  [branch]
  if (RENODX_TONE_MAP_TYPE == 0.f) {
    const float3 composite = max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * g_overlayNits))
                             + overlay.a * max(0.f, renodx::color::bt2020::from::BT709(scene)) * g_sceneNits;
    return float4(EncodeVanillaOutput(composite), output_alpha);
  }

  scene = renodx::color::grade::UserColorGrading(
      scene,
      RENODX_TONE_MAP_EXPOSURE,
      RENODX_TONE_MAP_HIGHLIGHTS,
      RENODX_TONE_MAP_SHADOWS,
      RENODX_TONE_MAP_CONTRAST,
      RENODX_TONE_MAP_SATURATION,
      0.f,
      0.f);
  const float3 scene_out_nits = ToneMapSceneRenoDX(max(0.f, renodx::color::bt2020::from::BT709(scene)) * overlay.a);
  return float4(renodx::color::pq::EncodeSafe(scene_out_nits + UINitsRenoDX(overlay.rgb), 1.f), output_alpha);
}
