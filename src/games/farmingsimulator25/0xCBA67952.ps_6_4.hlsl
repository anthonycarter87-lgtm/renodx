// FS25 UI-only composite (menus and loading screens without a 3D scene) -> HDR10 PQ.
// Vanilla uses FS25's Overlay Brightness and display curve; RenoDX outputs the UI linearly at UI Brightness.
#include "./common.hlsli"

Texture2D<float4> overlayTexture : register(t0);

cbuffer DeviceParameters : register(b0) {
  float4 g_sceneClipViewport : packoffset(c000.x);
  float g_screenMinNits : packoffset(c001.x);
  float g_screenMaxNits : packoffset(c001.y);
  float g_sceneNits : packoffset(c001.z);
  float g_overlayNits : packoffset(c001.w);
  float g_hdrGamma : packoffset(c002.x);
};

SamplerState overlaySampler : register(s0);

float4 main(
    noperspective float4 SV_Position: SV_Position,
    linear float2 TEXCOORD: TEXCOORD)
    : SV_Target {
  const float4 overlay = overlayTexture.Sample(overlaySampler, TEXCOORD);
  const float3 output = (RENODX_TONE_MAP_TYPE == 0.f)
                            ? EncodeVanillaOutput(max(0.f, renodx::color::bt2020::from::BT709(overlay.rgb * g_overlayNits)))
                            : renodx::color::pq::EncodeSafe(UINitsRenoDX(overlay.rgb), 1.f);
  return float4(output, 1.f - overlay.a);
}
