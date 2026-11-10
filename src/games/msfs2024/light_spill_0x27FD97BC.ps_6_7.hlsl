// ph_macro_lights: light cast onto the ground/scene by night lights. Light Spill slider. (0x27FD97BC)
#include "./common.hlsli"

Texture2D<float4> t0 : register(t0);

Texture2D<float4> t1 : register(t1);

cbuffer cb0 : register(b0) {
  struct StructGlobalConstant_Z {
    float4 StructGlobalConstant_Z_000[300];
  } CBufferGlobalConstant_Z_000 : packoffset(c000.x);
};

SamplerState s0 : register(s0);

float3 main(
  noperspective float4 SV_Position : SV_Position,
  nointerpolation float3 LIGHTPOS : LIGHTPOS,
  nointerpolation float VISIBILITY : VISIBILITY,
  nointerpolation float3 INTENSITY : INTENSITY,
  nointerpolation uint INSTANCE_ID : INSTANCE_ID,
  linear float2 UV : UV
) : SV_Target {
  float3 SV_Target;
  float _19 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].z) * SV_Position.x;
  float _20 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].w) * SV_Position.y;
  float _36 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[166].x) * LIGHTPOS.x;
  float _37 = mad(LIGHTPOS.y, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[166].y), _36);
  float _38 = mad(LIGHTPOS.z, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[166].z), _37);
  float _39 = _38 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[166].w);
  float _40 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[167].x) * LIGHTPOS.x;
  float _41 = mad(LIGHTPOS.y, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[167].y), _40);
  float _42 = mad(LIGHTPOS.z, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[167].z), _41);
  float _43 = _42 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[167].w);
  float _44 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[169].x) * LIGHTPOS.x;
  float _45 = mad(LIGHTPOS.y, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[169].y), _44);
  float _46 = mad(LIGHTPOS.z, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[169].z), _45);
  float _47 = _46 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[169].w);
  float _48 = _39 / _47;
  float _49 = _43 / _47;
  float _50 = _48 * 0.5f;
  float _51 = _49 * 0.5f;
  float _52 = _19 + -0.5f;
  float _53 = _52 - _50;
  float _54 = _20 + -0.5f;
  float _55 = _54 + _51;
  float _58 = _53 * 0.6666666865348816f;
  float _59 = _58 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].x);
  float _60 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].y) * 0.6666666865348816f;
  float _61 = _60 * _55;
  float _62 = LIGHTPOS.x * LIGHTPOS.x;
  float _63 = LIGHTPOS.y * LIGHTPOS.y;
  float _64 = _63 + _62;
  float _65 = LIGHTPOS.z * LIGHTPOS.z;
  float _66 = _64 + _65;
  float _67 = sqrt(_66);
  float _68 = dot(float2(_59, _61), float2(_59, _61));
  float _69 = saturate(_68);
  float _70 = 1.0f - _69;
  float _71 = _70 * _70;
  float _72 = _71 * 10.0f;
  float _73 = _72 * _70;
  float _74 = _67 + -200.0f;
  float _75 = _74 * 0.0012499999720603228f;
  float _76 = saturate(_75);
  float _77 = _76 * _76;
  float _78 = _77 * _76;
  float4 _80 = t0.Load(int3(0, 0, 0));
  float _82 = dot(float2(LIGHTPOS.x, LIGHTPOS.y), float2(LIGHTPOS.x, LIGHTPOS.y));
  float _83 = rsqrt(_82);
  float _84 = _83 * LIGHTPOS.x;
  float _85 = _83 * LIGHTPOS.y;
  float _86 = UV.x + -0.5f;
  float _87 = UV.y + -0.5f;
  float _88 = dot(float2(_86, _87), float2(_86, _87));
  float _89 = rsqrt(_88);
  float _90 = _89 * _86;
  float _91 = _89 * _87;
  float _92 = dot(float2(_90, _91), float2(_84, _85));
  float _93 = abs(_92);
  float _94 = _93 * _93;
  float _95 = 1.0f - _94;
  float _96 = _95 * 0.6000000238418579f;
  float _97 = _96 + 0.4000000059604645f;
  float4 _100 = t1.Sample(s0, float2(UV.x, UV.y));
  float _103 = _80.x * 6.665999889373779f;
  float _104 = _103 * _97;
  float _105 = _104 * _100.y;
  float _106 = _105 + _100.x;
  float _107 = log2(_106);
  float _108 = _107 * 4.5f;
  float _109 = exp2(_108);
  float _110 = 1.0f - _78;
  float _111 = _109 * _110;
  float _112 = _111 + _73;
  float _113 = _112 * INTENSITY.x;
  float _114 = _112 * INTENSITY.y;
  float _115 = _112 * INTENSITY.z;
  float _118 = _113 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL);
  float _119 = _114 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL);
  float _120 = _115 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL);
  SV_Target.x = _118;
  SV_Target.y = _119;
  SV_Target.z = _120;
  return SV_Target;
}
