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

#endif  // SRC_GAMES_MSFS2024_COMMON_HLSLI_
