#ifndef SRC_GAMES_FARMINGSIMULATOR25_COMMON_HLSLI_
#define SRC_GAMES_FARMINGSIMULATOR25_COMMON_HLSLI_

#include "./shared.h"

// The game's final curve: BT.709 camera OETF followed by a 2.4 display gamma, which adds contrast.
// Vanilla runs it per channel on the BT.2020 composite (oversaturating); RenoDX runs it on luminance.
float ApplyGameDisplayCurve(float y_nits, float reference_nits, float white_nits) {
  const float y_relative = y_nits / reference_nits;
  const float encoded = (y_relative <= 0.018f) ? (4.5f * y_relative) : (1.099f * pow(y_relative, 0.45f) - 0.099f);
  return white_nits * pow(max(encoded, 0.f), 2.4f);
}

// Vanilla output: FS25's curve per channel on a BT.2020 nits composite, then HDR10 PQ.
float3 EncodeVanillaOutput(float3 composite_bt2020_nits) {
  float3 output_nits;
  [unroll]
  for (int channel = 0; channel < 3; ++channel) {
    output_nits[channel] = ApplyGameDisplayCurve(composite_bt2020_nits[channel], 168.f, 100.f);
  }
  return renodx::color::pq::Encode(output_nits, 1.f);
}

// RenoDX scene tone map. Input: BT.2020 linear, 1.0 = Game Brightness. Output: BT.2020 nits.
// FS25's display curve (its shape at HDR 3D Brightness 410) is applied on luminance and normalised so mid-grey stays
// at 18% of Game Brightness, then highlights stay linear to half the peak and roll off smoothly to the peak.
float3 ToneMapSceneRenoDX(float3 graded_relative) {
  const float scene_nits = RENODX_DIFFUSE_WHITE_NITS;
  const float peak_nits = RENODX_PEAK_WHITE_NITS;

  const float curve_reference = 168.f / 410.f;
  const float mid_gray_scale = 0.18f / ApplyGameDisplayCurve(0.18f, curve_reference, 1.f);
  const float graded_y = renodx::color::y::from::BT2020(graded_relative);
  const float curved_y_nits = ApplyGameDisplayCurve(graded_y, curve_reference, mid_gray_scale) * scene_nits;

  const float knee_nits = 0.5f * peak_nits;
  const float tonemapped_y_nits = (curved_y_nits <= knee_nits)
                                      ? curved_y_nits
                                      : (knee_nits + renodx::tonemap::Neutwo(curved_y_nits - knee_nits, peak_nits - knee_nits));
  float3 scene_out_nits = graded_relative * renodx::math::DivideSafe(tonemapped_y_nits, graded_y, 0.f);

  const float scene_y_final = renodx::color::y::from::BT2020(scene_out_nits);
  const float peak_fraction = saturate(scene_y_final / peak_nits);
  scene_out_nits = scene_y_final + (scene_out_nits - scene_y_final) * lerp(1.f, RENODX_TONE_MAP_HIGHLIGHT_SATURATION, peak_fraction);
  scene_out_nits = lerp(scene_out_nits, scene_y_final.xxx, RENODX_TONE_MAP_BLOWOUT * peak_fraction * peak_fraction);
  return scene_out_nits;
}

// UI in RenoDX mode: BT.2020 nits. Keeps FS25's per-channel display curve (its shape at Overlay Brightness 400) so UI
// and 2D menu art keep the game's contrast, normalised like the scene: mid-grey at 18% of UI Brightness
// (UI white then lands ~1.38x above it, as in the game).
float3 UINitsRenoDX(float3 overlay_bt709) {
  const float curve_reference = 168.f / 400.f;
  const float3 ui_bt2020 = max(0.f, renodx::color::bt2020::from::BT709(overlay_bt709));
  float3 ui_nits;
  [unroll]
  for (int channel = 0; channel < 3; ++channel) {
    ui_nits[channel] = ApplyGameDisplayCurve(ui_bt2020[channel], curve_reference, 1.f);
  }
  return ui_nits * (RENODX_GRAPHICS_WHITE_NITS * 0.18f / ApplyGameDisplayCurve(0.18f, curve_reference, 1.f));
}

#endif  // SRC_GAMES_FARMINGSIMULATOR25_COMMON_HLSLI_
