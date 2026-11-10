#ifndef SRC_GAMES_MSFS2024_SHARED_H_
#define SRC_GAMES_MSFS2024_SHARED_H_

// 1 = crash test without the settings channel (sliders do nothing).
#define MSFS2024_NO_INJECTION 1

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
  float padding_0;
};

#ifndef __cplusplus
#if MSFS2024_NO_INJECTION
// Build 2c crash test: fixed defaults, no injected cbuffer (game root signatures untouched).
static const ShaderInjectData shader_injection = {
    1.f, 1000.f, 203.f, 203.f, 1.f, 1.f, 1.f, 1.f, 1.f, 1.f, 0.f, 0.f};
#else
cbuffer shader_injection : register(b13, space50) {
  ShaderInjectData shader_injection : packoffset(c0);
}
#endif

// tone_map_type is the UI setting (0 = Vanilla, 1 = RenoDX); the shaders map RenoDX to RenoDRT themselves.
#define RENODX_PEAK_WHITE_NITS               shader_injection.peak_white_nits
#define RENODX_DIFFUSE_WHITE_NITS            shader_injection.diffuse_white_nits
#define RENODX_GRAPHICS_WHITE_NITS           shader_injection.graphics_white_nits
#define RENODX_TONE_MAP_EXPOSURE             shader_injection.tone_map_exposure
#define RENODX_TONE_MAP_HIGHLIGHTS           shader_injection.tone_map_highlights
#define RENODX_TONE_MAP_SHADOWS              shader_injection.tone_map_shadows
#define RENODX_TONE_MAP_CONTRAST             shader_injection.tone_map_contrast
#define RENODX_TONE_MAP_SATURATION           shader_injection.tone_map_saturation
#define RENODX_TONE_MAP_HIGHLIGHT_SATURATION shader_injection.tone_map_highlight_saturation
#define RENODX_TONE_MAP_BLOWOUT              shader_injection.tone_map_blowout
#define RENODX_TONE_MAP_TYPE                 renodx::draw::TONE_MAP_TYPE_RENO_DRT

#include "../../shaders/renodx.hlsl"

#endif

#endif  // SRC_GAMES_MSFS2024_SHARED_H_
