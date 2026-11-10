// ph_billboard_lights: light bulbs/flares (runway, city, aircraft). Light Glow slider. (0x5317B8AF)
#include "./common.hlsli"

Texture2D<float4> t0 : register(t0);

Texture2D<float4> t1 : register(t1);

cbuffer cb0 : register(b0) {
  struct StructGlobalConstant_Z {
    float4 StructGlobalConstant_Z_000[300];
  } CBufferGlobalConstant_Z_000 : packoffset(c000.x);
};

SamplerState s0 : register(s0);

struct OutputSignature {
  float4 SV_Target : SV_Target;
  float4 SV_Target_1 : SV_Target1;
};

OutputSignature main(
  nointerpolation float4 LightPos : LightPos,
  nointerpolation float4 Color : Color,
  noperspective float4 SV_Position : SV_Position,
  nointerpolation float EnergyConservation : EnergyConservation,
  nointerpolation uint TAAMASK : TAAMASK,
  noperspective float2 FlareUV : FlareUV
) {
  float4 SV_Target;
  float4 SV_Target_1;
  bool _7 = (TAAMASK == 0);
  float _17 = Color.x * EnergyConservation;
  float _18 = Color.y * EnergyConservation;
  float _19 = Color.z * EnergyConservation;
  float4 _21 = t0.Load(int3(0, 0, 0));
  float _23 = dot(float2(FlareUV.x, FlareUV.y), float2(FlareUV.x, FlareUV.y));
  float _41;
  if (!_7) {
    float _25 = ddy_coarse(FlareUV.y);
    float _26 = abs(_25);
    float _27 = ddx_coarse(FlareUV.x);
    float _28 = abs(_27);
    float _29 = max(_28, _26);
    float _30 = _29 + 1.0f;
    float _31 = _30 * _30;
    bool _32 = (_23 < _31);
    if (_32) {
      float _34 = _23 * 2.0f;
      float _35 = _34 / _21.x;
      float _36 = max(_18, _19);
      float _37 = max(_17, _36);
      bool _38 = (_37 > _35);
      if (_38) {
        _41 = -1.0f;
      } else {
        _41 = 0.0f;
      }
    } else {
      _41 = 0.0f;
    }
  } else {
    _41 = 0.0f;
  }
  float _42 = LightPos.x * LightPos.x;
  float _43 = LightPos.y * LightPos.y;
  float _44 = _43 + _42;
  float _45 = LightPos.z * LightPos.z;
  float _46 = _44 + _45;
  float _47 = sqrt(_46);
  float _48 = _47 + -200.0f;
  float _49 = _48 * 0.0007692307699471712f;
  float _50 = saturate(_49);
  float _51 = _47 * 0.03999999910593033f;
  float _52 = _51 + 0.20000000298023224f;
  float _53 = 1.0f / _52;
  float _54 = _53 + 1.0f;
  float _55 = dot(float2(LightPos.x, LightPos.y), float2(LightPos.x, LightPos.y));
  float _56 = rsqrt(_55);
  float _57 = _56 * LightPos.x;
  float _58 = _56 * LightPos.y;
  float _59 = rsqrt(_23);
  float _60 = _59 * FlareUV.x;
  float _61 = _59 * FlareUV.y;
  float _62 = dot(float2(_57, _58), float2(_60, _61));
  float _63 = abs(_62);
  float _64 = _63 * 0.699999988079071f;
  float _65 = _64 + 0.4000000059604645f;
  float _66 = _54 * FlareUV.x;
  float _67 = _54 * FlareUV.y;
  float _68 = _66 + 2.5f;
  float _69 = _67 + 2.5f;
  float _70 = _68 * 0.009999999776482582f;
  float _71 = _69 * 0.009999999776482582f;
  float _72 = _70 + 0.4749999940395355f;
  float _73 = _71 + 0.4749999940395355f;
  float _74 = saturate(_23);
  float _75 = 1.0f - _74;
  float4 _78 = t1.Sample(s0, float2(_72, _73));
  float _81 = _50 * 2.0f;
  float _82 = 2.5f - _81;
  float _83 = _21.x * 6.665999889373779f;
  float _84 = saturate(_83);
  float _85 = _78.y * _65;
  float _86 = _85 * _84;
  float _87 = _86 + _78.x;
  float _88 = _82 * _87;
  float _89 = _88 * 0.17000000178813934f;
  float _90 = log2(_89);
  float _91 = _90 * 4.5f;
  float _92 = exp2(_91);
  float _93 = 1.0f - _50;
  float _94 = _92 * _93;
  float _95 = _75 * _75;
  float _96 = _95 * _50;
  float _97 = _96 * _75;
  float _98 = _94 + _97;
  float _99 = _98 * _17;
  float _100 = _98 * _18;
  float _101 = _98 * _19;
  float _104 = _99 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  float _105 = _100 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  float _106 = _101 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  SV_Target_1.x = _41;
  SV_Target_1.y = 0.0f;
  SV_Target_1.z = 0.0f;
  SV_Target_1.w = 0.0f;
  SV_Target.x = _104;
  SV_Target.y = _105;
  SV_Target.z = _106;
  SV_Target.w = 1.0f;
  OutputSignature output_signature = { SV_Target, SV_Target_1 };
  return output_signature;
}
