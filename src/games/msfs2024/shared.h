#ifndef SRC_GAMES_MSFS2024_SHARED_H_
#define SRC_GAMES_MSFS2024_SHARED_H_

// 1 = shaders use fixed defaults instead of the injected settings buffer (crash investigation, build 2e).
#define MSFS2024_NO_INJECTION 0

// Must be 32bit aligned
// Should be 4x32 (multiple of 4 floats)
struct ShaderInjectData {
  float tone_map_type;
  float peak_white_nits;
  float diffuse_white_nits;
  float graphics_white_nits;
  float tone_map_exposure;
  float tone_map_highlights;
  float tone_map_shadows;
  float tone_map_contrast;
  float tone_map_saturation;
  float tone_map_highlight_saturation;
  float tone_map_blowout;
  float gamut_expansion;
  float wide_colour;  // 1 when the 16-bit render target upgrade is active (set by the addon at startup)
  float sharpness;
  float padding_0;
  float padding_1;
};

#ifndef __cplusplus
#if MSFS2024_NO_INJECTION
// Build 2c crash test: fixed defaults, no injected cbuffer (game root signatures untouched).
static const ShaderInjectData shader_injection = {
    1.f, 1000.f, 203.f, 203.f, 1.f, 1.f, 1.f, 1.f, 1.f, 1.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f};
#else
cbuffer shader_injection : register(b13, space50) {
  ShaderInjectData shader_injection : packoffset(c0);
}
#endif

// tone_map_type is the UI setting (0 = Vanilla, 1 = RenoDX); the shaders map RenoDX to RenoDRT themselves.
#define RENODX_PEAK_WHITE_NITS               shader_injection.peak_white_nits
// Calibrated like FS25: the sliders read the RenoDX standard 203, but 203 gives MSFS's own brightness.
// Measured/tuned 10 Nov 2026: the game's look needs 366 nits scene white and 300 nits UI white.
#define MSFS2024_GAME_BRIGHTNESS_SCALE       (366.f / 203.f)
#define MSFS2024_UI_BRIGHTNESS_SCALE         (300.f / 203.f)
#define RENODX_DIFFUSE_WHITE_NITS            (shader_injection.diffuse_white_nits * MSFS2024_GAME_BRIGHTNESS_SCALE)
#define RENODX_GRAPHICS_WHITE_NITS           (shader_injection.graphics_white_nits * MSFS2024_UI_BRIGHTNESS_SCALE)
#define RENODX_TONE_MAP_EXPOSURE             shader_injection.tone_map_exposure
#define RENODX_TONE_MAP_HIGHLIGHTS           shader_injection.tone_map_highlights
#define RENODX_TONE_MAP_SHADOWS              shader_injection.tone_map_shadows
#define RENODX_TONE_MAP_CONTRAST             shader_injection.tone_map_contrast
#define RENODX_TONE_MAP_SATURATION           shader_injection.tone_map_saturation
#define RENODX_TONE_MAP_HIGHLIGHT_SATURATION shader_injection.tone_map_highlight_saturation
#define RENODX_TONE_MAP_BLOWOUT              shader_injection.tone_map_blowout
#define RENODX_TONE_MAP_TYPE                 renodx::draw::TONE_MAP_TYPE_RENO_DRT
#define MSFS2024_SHARPNESS                   shader_injection.sharpness
#define MSFS2024_GAMUT_EXPANSION             shader_injection.gamut_expansion
#define MSFS2024_WIDE_COLOUR                 (shader_injection.wide_colour != 0.f)

#include "../../shaders/renodx.hlsl"

#endif

#endif  // SRC_GAMES_MSFS2024_SHARED_H_
