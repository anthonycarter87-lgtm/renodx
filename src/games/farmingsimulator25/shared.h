#ifndef SRC_GAMES_FARMINGSIMULATOR25_SHARED_H_
#define SRC_GAMES_FARMINGSIMULATOR25_SHARED_H_

// Must be 32bit aligned
// Should be 4x32
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
  float color_grade_strength;
  float custom_ao_strength;
  float custom_ao_radius;
  float padding_2;
  float padding_3;
};

#ifndef __cplusplus
cbuffer shader_injection : register(b13, space50) {
  ShaderInjectData shader_injection : packoffset(c0);
}

#define RENODX_TONE_MAP_TYPE                 shader_injection.tone_map_type
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
#define RENODX_COLOR_GRADE_STRENGTH          shader_injection.color_grade_strength
#define CUSTOM_AO_STRENGTH                   shader_injection.custom_ao_strength
#define CUSTOM_AO_RADIUS                     shader_injection.custom_ao_radius

// RenoDX replaces all of FS25's HDR Calibration values (3D brightness, overlay brightness, HDR contrast and the
// display peak the game reads from Windows) with the RenoDX sliders.
// FS25's HDR Contrast is a per-channel power curve; it is kept out of the LUT and applied by the output shader in
// Vanilla mode only (RenoDX uses its Contrast slider instead).
#define FS25_LUT_HDR_GAMMA 1.f

#include "../../shaders/renodx.hlsl"

#endif

#endif  // SRC_GAMES_FARMINGSIMULATOR25_SHARED_H_
