#ifndef SRC_GAMES_MSFS2024_COMMON_HLSLI_
#define SRC_GAMES_MSFS2024_COMMON_HLSLI_

#include "./shared.h"

bool UseRenoDX() {
  return shader_injection.tone_map_type != 0.f;
}

// ph_tonemapping, RenoDX mode. Replaces Asobo's toe (black lift) and peak shoulder.
// Input: the graded scene straight after the game's HDR grading LUT, BT.709 linear, where 1.0 is the game's
// reference white (PostProcessConstant[10].w nits).
// Output: BT.709 linear in UI units (1.0 = UI Brightness), because MSFS draws its UI into the same
// buffer and ph_2d_HDR10 scales the whole frame by UI Brightness.
//
// Wide colour (v1.1 test): with the 16-bit upgrade the buffer can hold negative BT.709 values, i.e. colours
// outside BT.709. Gamut Expansion reads the game's BT.709 colours as if they were Display P3, which
// spreads saturated colours into the wider HDR gamut. Greys and white don't move.
float3 ToneMapScene(float3 graded_bt709) {
  float3 tonemapped = renodx::draw::ToneMapPass(max(0.f, graded_bt709));
  tonemapped = max(0.f, tonemapped);
  if (MSFS2024_WIDE_COLOUR && MSFS2024_GAMUT_EXPANSION > 0.f) {
    float3 expanded = mul(renodx::color::DISPLAYP3_TO_BT709_MAT, tonemapped);
    tonemapped = lerp(tonemapped, expanded, MSFS2024_GAMUT_EXPANSION);
  }
  return tonemapped * (RENODX_DIFFUSE_WHITE_NITS / RENODX_GRAPHICS_WHITE_NITS);
}

// Eye adaptation (ph_lumadaptation, decoded 10 Nov): adaptation = key / L, where L is the scene's adapted
// luminance clamped to [min, max]. key/min/max = PostProcessConstant[0].xyz (assumed to be the same values in
// the tonemapper; the readout below checks that).
// Strength scales L's distance from the middle of its allowed range in log2 space:
// 1 = game, 0 = fixed exposure, 2 = double the swings.
float AdjustAdaptation(float adaptation, float3 key_min_max) {
  const float strength = MSFS2024_ADAPTATION_STRENGTH;
  if (strength == 1.f) return adaptation;
  const float key = key_min_max.x;
  const float lum_min = key_min_max.y;
  const float lum_max = key_min_max.z;
  if (!(adaptation > 0.f) || !(key > 0.f) || !(lum_min > 0.f) || !(lum_max > lum_min)) return adaptation;

  const float log_lum = log2(key / adaptation);
  const float log_pivot = 0.5f * (log2(lum_min) + log2(lum_max));
  float new_log_lum = lerp(log_pivot, log_lum, strength);
  new_log_lum = clamp(new_log_lum, log2(lum_min) - 2.f, log2(lum_max) + 2.f);
  return key / exp2(new_log_lum);
}

// Debug: 4 grey squares top-left = log2 of (adaptation, key, min, max). Read back from an HDR screenshot.
// Encoding: UI-linear value v = (log2(x) + 32) / 64, so 0..1 covers 2^-32..2^32.
float3 AdaptationReadout(float3 color, float2 position, float raw_adaptation, float3 key_min_max) {
  if (!MSFS2024_ADAPTATION_READOUT) return color;
  if (position.y >= 64.f || position.x >= 256.f) return color;
  const uint index = (uint)(position.x / 64.f);
  float value = raw_adaptation;
  if (index == 1u) value = key_min_max.x;
  if (index == 2u) value = key_min_max.y;
  if (index == 3u) value = key_min_max.z;
  const float encoded = saturate((log2(max(value, 1e-30f)) + 32.f) / 64.f);
  return encoded.xxx;
}

#endif  // SRC_GAMES_MSFS2024_COMMON_HLSLI_
