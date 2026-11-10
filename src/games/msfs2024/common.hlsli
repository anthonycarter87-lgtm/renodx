#ifndef SRC_GAMES_MSFS2024_COMMON_HLSLI_
#define SRC_GAMES_MSFS2024_COMMON_HLSLI_

#include "./shared.h"

// Tone Mapper setting: 0 = Vanilla (untouched game), 1 = RenoDX, 2 = Asobo (game curve, display peak).
bool UseCustomOutput() {
  return shader_injection.tone_map_type != 0.f;
}

// Asobo's HDR curve values from PostProcessConstant, all in nits.
struct AsoboCurve {
  float reference_nits;  // [10].w: graded 1.0 = this many nits
  float toe_end_nits;    // [16].z
  float toe_lift_nits;   // [15].w
  float shoulder_nits;   // [16].w
};

// Asobo's curve per channel, exactly as ph_tonemapping does it, but rescaled to Game Brightness and rolling
// off to the RenoDX Peak instead of the game's own (very high) peak.
float3 ToneMapAsobo(float3 graded_bt709, AsoboCurve curve) {
  const float scale = RENODX_DIFFUSE_WHITE_NITS / curve.reference_nits;
  const float toe_end = curve.toe_end_nits * scale;
  const float toe_lift = curve.toe_lift_nits * scale;
  const float peak = RENODX_PEAK_WHITE_NITS;
  const float shoulder = min(curve.shoulder_nits * scale, 0.5f * peak);

  float3 nits = max(0.f, graded_bt709) * RENODX_DIFFUSE_WHITE_NITS;
  [unroll]
  for (int channel = 0; channel < 3; ++channel) {
    float value = nits[channel];
    if (toe_end > 0.f && value < toe_end) {
      const float toe = 1.f - value / toe_end;
      value += toe * toe * toe_lift;
    }
    if (value >= shoulder) {
      value = shoulder + (1.f - exp(-(value - shoulder) / (peak - shoulder))) * (peak - shoulder);
    }
    nits[channel] = value;
  }
  return nits;
}

// ph_tonemapping, custom modes. Replaces Asobo's toe (black lift) and peak shoulder.
// Input: the graded scene straight after the game's HDR grading LUT, BT.709 linear, where 1.0 is the game's
// reference white (curve.reference_nits).
// Output: BT.709 linear in UI units (1.0 = UI Brightness), because MSFS draws its UI into the same
// buffer and ph_2d_HDR10 scales the whole frame by UI Brightness.
float3 ToneMapScene(float3 graded_bt709, AsoboCurve curve) {
  if (shader_injection.tone_map_type == 2.f) {
    return ToneMapAsobo(graded_bt709, curve) / RENODX_GRAPHICS_WHITE_NITS;
  }
  float3 tonemapped = renodx::draw::ToneMapPass(max(0.f, graded_bt709));
  return max(0.f, tonemapped) * (RENODX_DIFFUSE_WHITE_NITS / RENODX_GRAPHICS_WHITE_NITS);
}

#endif  // SRC_GAMES_MSFS2024_COMMON_HLSLI_
