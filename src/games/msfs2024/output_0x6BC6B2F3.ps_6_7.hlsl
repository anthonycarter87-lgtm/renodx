// ph_2d_HDR10: MSFS 2024's final full-screen pass to the HDR10 swap chain.
// Input t0 is the finished frame (scene + UI) in sRGB encoding.
// Hand-written: the decompiler can't handle the original, which also has
// developer test patterns (UserConstant[3].x > 0) that aren't reproduced here.
#include "./common.hlsli"

Texture2D<float4> t0 : register(t0);
Texture2DArray<float4> t1 : register(t1);
SamplerState s0 : register(s0);

cbuffer cb0 : register(b0) {
  float4 user_constants[658];
};

// The game's own sRGB decode (piecewise, 0.04045 threshold).
float3 DecodeGameSRGB(float3 encoded) {
  float3 curve = exp2(log2((encoded + 0.054999999701976776f) * 0.9478673338890076f) * 2.4000000953674316f);
  return select(encoded <= 0.040449999272823334f, encoded * 0.07739938050508499f, curve);
}

// The game's sRGB encode, used by its optional "gamma 2.2" emulation.
float3 EncodeGameSRGB(float3 linear_color) {
  float3 curve = exp2(log2(linear_color) * 0.4166666567325592f) * 1.0549999475479126f - 0.054999999701976776f;
  return select(linear_color <= 0.0031308000907301903f, linear_color * 12.920000076293945f, curve);
}

float3 VanillaBT2020Nits(float3 frame_srgb) {
  float3 frame_nits = DecodeGameSRGB(frame_srgb) * user_constants[0].x;
  if (asint(user_constants[2].x) != 0) {
    float3 gamma_22 = exp2(log2(EncodeGameSRGB(frame_nits)) * 2.200000047683716f);
    frame_nits = select(frame_nits < 1.f, gamma_22, frame_nits);
  }

  float3 bt2020_nits = float3(
      dot(frame_nits, float3(0.627403974533081f, 0.3292819857597351f, 0.04331360012292862f)),
      dot(frame_nits, float3(0.06909699738025665f, 0.9195399880409241f, 0.011361200362443924f)),
      dot(frame_nits, float3(0.01639159955084324f, 0.08801320195198059f, 0.8955950140953064f)));
  if (asint(user_constants[3].y) != 0) {
    bt2020_nits = dot(bt2020_nits, float3(0.26269999146461487f, 0.6779999732971191f, 0.059300001710653305f)).xxx;
  }
  return bt2020_nits;
}

float4 main(
    linear float4 COLOR : COLOR,
    linear float4 TEXCOORD : TEXCOORD,
    noperspective float4 SV_Position : SV_Position,
    nointerpolation uint INSTANCE_ID : INSTANCE_ID) : SV_Target {
  float3 frame_srgb = t0.SampleLevel(s0, TEXCOORD.xy, 0.f).rgb;

  float3 bt2020_nits;
  if (UseRenoDX()) {
    float3 frame_linear = max(0.f, DecodeGameSRGB(frame_srgb));
    bt2020_nits = renodx::color::bt2020::from::BT709(frame_linear) * RENODX_GRAPHICS_WHITE_NITS;
  } else {
    bt2020_nits = VanillaBT2020Nits(frame_srgb);
  }

  float3 pq = renodx::color::pq::Encode(abs(bt2020_nits), 1.f);

  uint2 dither_coord = uint2(SV_Position.xy) & 63u;
  float dither = (t1.Load(int4(dither_coord, 0, 0)).x - 0.5f) * 0.0009775171056389809f;
  return float4(saturate(pq + dither), 1.f);
}
