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
// Tone Mapper setting: 0 Vanilla (not used here), 1 RenoDRT, 2 Psycho (psychov test17), 3 ACES.
// (test35 was tried in build 16: no visible difference from test17 in MSFS, so not offered.)
float3 ToneMapScene(float3 graded_bt709) {
  graded_bt709 = max(0.f, graded_bt709);
  float3 tonemapped;
  if (shader_injection.tone_map_type >= 2.5f) {
    renodx::draw::Config config = renodx::draw::BuildConfig();
    config.tone_map_type = renodx::draw::TONE_MAP_TYPE_ACES;
    tonemapped = renodx::draw::ToneMapPass(graded_bt709, config);
  } else if (shader_injection.tone_map_type >= 1.5f) {
    // Psycho: perceptual tone mapper. In MSFS testing (24 Nov) bright sky/clouds came out ~40% less saturated
    // than RenoDRT and mid-tones brighter. Same sliders as RenoDRT, except Highlight Saturation and Blowout.
    tonemapped = renodx::tonemap::psychov::psychotm_test17(
        graded_bt709,
        RENODX_PEAK_WHITE_NITS / RENODX_DIFFUSE_WHITE_NITS,  // peak relative to game white
        RENODX_TONE_MAP_EXPOSURE,
        RENODX_TONE_MAP_HIGHLIGHTS,
        RENODX_TONE_MAP_SHADOWS,
        RENODX_TONE_MAP_CONTRAST,
        RENODX_TONE_MAP_SATURATION,  // purity
        1.f,                         // bleaching intensity
        100.f,                       // clip point
        1.f,                         // hue restore
        1.f,                         // adaptation contrast
        0,                           // white curve mode
        1.f);                        // cone response exponent
    tonemapped = renodx::color::bt709::clamp::BT709(tonemapped);
  } else {
    tonemapped = renodx::draw::ToneMapPass(graded_bt709);
  }
  tonemapped = max(0.f, tonemapped);
  return tonemapped * (RENODX_DIFFUSE_WHITE_NITS / RENODX_GRAPHICS_WHITE_NITS);
}

// Black Floor Fix: MSFS's grading LUT (t3) can map pure black to a raised value (Lilium analyser: raised
// night blacks with RenoDX on, reported by Energyzer 20 Nov). Read what black becomes by sampling the LUT at
// its black coordinate (the log encode gives u = offset for x = 0), decode it like the game does, then remove
// that floor per channel with a linear remap that is fully applied at black and gone by mid grey.
float3 SampleLutBlack(Texture3D<float4> lut, SamplerState lut_sampler, float lut_offset, float reference_nits,
                      float3 user_tint) {
  float3 encoded = lut.SampleLevel(lut_sampler, lut_offset.xxx, 0.f).rgb;
  float3 decoded = (exp2(encoded * 13.450128555297852f) - 1.f) * 8.936070662457496e-05f;
  return decoded * (10000.f / reference_nits) * user_tint;
}

float3 FixBlackFloor(float3 graded, float3 lut_black) {
  const float strength = MSFS2024_BLACK_FLOOR_FIX;
  if (strength <= 0.f) return graded;
  static const float FADE_END = 0.18f;  // fully faded out by mid grey (1.0 = game reference white)
  float3 floor_value = clamp(lut_black * strength, 0.f, FADE_END * 0.5f);
  float3 remapped = max(0.f, graded - floor_value) * (FADE_END / (FADE_END - floor_value));
  return select(graded < FADE_END, remapped, graded);
}

#endif  // SRC_GAMES_MSFS2024_COMMON_HLSLI_
