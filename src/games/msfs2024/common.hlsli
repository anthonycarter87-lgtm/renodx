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
float3 ToneMapScene(float3 graded_bt709) {
  float3 tonemapped = renodx::draw::ToneMapPass(max(0.f, graded_bt709));
  return max(0.f, tonemapped) * (RENODX_DIFFUSE_WHITE_NITS / RENODX_GRAPHICS_WHITE_NITS);
}

#endif  // SRC_GAMES_MSFS2024_COMMON_HLSLI_
