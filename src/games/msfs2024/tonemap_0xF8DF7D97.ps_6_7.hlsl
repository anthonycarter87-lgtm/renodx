// ph_tonemapping variant 18 (0xF8DF7D97) - build 1 debug tint
#include "./debug.hlsli"

Texture2DArray<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s0 : register(s0);

float4 main(
  linear float4 TEXCOORD : TEXCOORD,
  noperspective float4 SV_Position : SV_Position
) : SV_Target {
  float4 SV_Target;
  float4 _10 = t0.Sample(s0, float2(TEXCOORD.z, TEXCOORD.w));
  float _15 = log2(_10.x);
  float _16 = log2(_10.y);
  float _17 = log2(_10.z);
  float _18 = _15 * 0.4166666567325592f;
  float _19 = _16 * 0.4166666567325592f;
  float _20 = _17 * 0.4166666567325592f;
  float _21 = exp2(_18);
  float _22 = exp2(_19);
  float _23 = exp2(_20);
  float _24 = _21 * 1.0549999475479126f;
  float _25 = _22 * 1.0549999475479126f;
  float _26 = _23 * 1.0549999475479126f;
  float _27 = _24 + -0.054999999701976776f;
  float _28 = _25 + -0.054999999701976776f;
  float _29 = _26 + -0.054999999701976776f;
  float _30 = _10.x * 12.920000076293945f;
  float _31 = _10.y * 12.920000076293945f;
  float _32 = _10.z * 12.920000076293945f;
  bool _33 = (_10.x <= 0.0031308000907301903f);
  bool _34 = (_10.y <= 0.0031308000907301903f);
  bool _35 = (_10.z <= 0.0031308000907301903f);
  float _36 = select(_33, _30, _27);
  float _37 = select(_34, _31, _28);
  float _38 = select(_35, _32, _29);
  uint _39 = uint(SV_Position.x);
  uint _40 = uint(SV_Position.y);
  int _41 = _39 & 63;
  int _42 = _40 & 63;
  float4 _44 = t1.Load(int4(_41, _42, 0, 0));
  float _46 = _44.x + -0.5f;
  float _47 = _46 * 0.003921568859368563f;
  float _48 = _47 + _36;
  float _49 = _47 + _37;
  float _50 = _47 + _38;
  float _51 = saturate(_48);
  float _52 = saturate(_49);
  float _53 = saturate(_50);
  SV_Target.x = _51;
  SV_Target.y = _52;
  SV_Target.z = _53;
  SV_Target.w = _10.w;
  SV_Target.rgb = DebugTint(SV_Target.rgb, SV_Position.xy, 18u);
  return SV_Target;
}
