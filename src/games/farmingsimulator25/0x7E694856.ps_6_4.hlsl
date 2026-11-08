// FS25 SSR apply: reflection = lerp(SSR colour, envMap, skyContribution) x specular weight. Structured decompile,
// dx.op counts match the original. RenoDX: with Wet Ground or Puddles on, skyContribution (SSR "ray missed, use the
// sky probe" weight) is softened with a small cross blur - its hard edge showed as straight lines across mirror puddles.
#include "./shared.h"

Texture2D<float3> ssrInput : register(t0);

Texture2D<float3> sceneColor : register(t1);

Texture2D<float3> miplevelMips : register(t2);

Texture2D<float> sceneDepth : register(t3);

Texture2D<float4> worldNormalsRoughnessDepth : register(t4);

TextureCube<float3> envMap : register(t5);

Texture2D<float2> skyContribution : register(t6);

cbuffer SSRApplyData : register(b0) {
  row_major float4x4 invViewProjMatrix : packoffset(c000.x);
  row_major float3x4 invViewMatrix : packoffset(c004.x);
  float2 sceneDepthTextureSize : packoffset(c007.x);
  float2 lowResSize : packoffset(c007.z);
};

SamplerState samplerTrilinearClamp : register(s0);


float SkyContributionSoft(float2 uv, float lod) {
  float2 px = 2.5f / lowResSize;
  float c = skyContribution.SampleLevel(samplerTrilinearClamp, uv, lod).x * 0.4f;
  c += skyContribution.SampleLevel(samplerTrilinearClamp, uv + float2(px.x, 0), lod).x * 0.15f;
  c += skyContribution.SampleLevel(samplerTrilinearClamp, uv - float2(px.x, 0), lod).x * 0.15f;
  c += skyContribution.SampleLevel(samplerTrilinearClamp, uv + float2(0, px.y), lod).x * 0.15f;
  c += skyContribution.SampleLevel(samplerTrilinearClamp, uv - float2(0, px.y), lod).x * 0.15f;
  return c;
}

float4 main(
  noperspective float4 SV_Position : SV_Position,
  linear float2 TEXCOORD : TEXCOORD,
  nointerpolation uint SV_SampleIndex : SV_SampleIndex
) : SV_Target {
  float4 SV_Target;
  float _15 = sceneDepthTextureSize.x * TEXCOORD.x;
  float _16 = sceneDepthTextureSize.y * TEXCOORD.y;
  uint _17 = uint(_15);
  uint _18 = uint(_16);
  float _19 = float((uint)_17);
  float _20 = float((uint)_18);
  float _21 = _19 + 0.5f;
  float _22 = _20 + 0.5f;
  float _23 = _21 / sceneDepthTextureSize.x;
  float _24 = _22 / sceneDepthTextureSize.y;
  float3 _25 = ssrInput.Load(int3(_17, _18, 0));
  float3 _29 = sceneColor.SampleLevel(samplerTrilinearClamp, float2(_23, _24), 0.0f);
  float3 _33 = miplevelMips.SampleLevel(samplerTrilinearClamp, float2(_23, _24), 0.0f);
  float _35 = _33.x * 6.0f;
  float _36 = sceneDepth.Load(int3(_17, _18, 0));
  float4 _38 = worldNormalsRoughnessDepth.Load(int3(_17, _18, 0));
  bool _43 = !(_38.w == 0.0f);
  float _44 = select(_43, _38.w, _36.x);
  float _45 = _38.x * 2.0f;
  float _46 = _38.y * 2.0f;
  float _47 = _45 + -1.0f;
  float _48 = _46 + -1.0f;
  float _49 = abs(_47);
  float _50 = 1.0f - _49;
  float _51 = abs(_48);
  float _52 = _50 - _51;
  float _53 = -0.0f - _52;
  float _54 = saturate(_53);
  int _55 = asint(_47);
  int _56 = asint(_48);
  int _57 = _55 & -2147483648;
  int _58 = _56 & -2147483648;
  int _59 = _57 | 1065353216;
  int _60 = _58 | 1065353216;
  float _61 = asfloat(_59);
  float _62 = asfloat(_60);
  float _63 = _61 * _54;
  float _64 = _62 * _54;
  float _65 = _47 - _63;
  float _66 = _48 - _64;
  float _67 = dot(float3(_65, _66, _52), float3(_65, _66, _52));
  float _68 = rsqrt(_67);
  float _69 = _65 * _68;
  float _70 = _66 * _68;
  float _71 = _68 * _52;
  float _98 = 1.0f - _24;
  float _99 = _23 * 2.0f;
  float _100 = _98 * 2.0f;
  float _101 = _99 + -1.0f;
  float _102 = _100 + -1.0f;
  float _103 = (invViewProjMatrix[0].x) * _101;
  float _104 = mad((invViewProjMatrix[0].y), _102, _103);
  float _105 = mad((invViewProjMatrix[0].z), _44, _104);
  float _106 = _105 + (invViewProjMatrix[0].w);
  float _107 = (invViewProjMatrix[1].x) * _101;
  float _108 = mad((invViewProjMatrix[1].y), _102, _107);
  float _109 = mad((invViewProjMatrix[1].z), _44, _108);
  float _110 = _109 + (invViewProjMatrix[1].w);
  float _111 = (invViewProjMatrix[2].x) * _101;
  float _112 = mad((invViewProjMatrix[2].y), _102, _111);
  float _113 = mad((invViewProjMatrix[2].z), _44, _112);
  float _114 = _113 + (invViewProjMatrix[2].w);
  float _115 = (invViewProjMatrix[3].x) * _101;
  float _116 = mad((invViewProjMatrix[3].y), _102, _115);
  float _117 = mad((invViewProjMatrix[3].z), _44, _116);
  float _118 = _117 + (invViewProjMatrix[3].w);
  float _119 = _106 / _118;
  float _120 = _110 / _118;
  float _121 = _114 / _118;
  float _122 = _119 - (invViewMatrix[0].w);
  float _123 = _120 - (invViewMatrix[1].w);
  float _124 = _121 - (invViewMatrix[2].w);
  float _125 = dot(float3(_122, _123, _124), float3(_122, _123, _124));
  float _126 = rsqrt(_125);
  float _127 = _126 * _122;
  float _128 = _126 * _123;
  float _129 = _126 * _124;
  float _130 = _38.z + -0.07999999821186066f;
  float _131 = dot(float3(_127, _128, _129), float3(_69, _70, _71));
  float _132 = _131 * 2.0f;
  float _133 = _132 * _69;
  float _134 = _132 * _70;
  float _135 = _132 * _71;
  float _136 = _127 - _133;
  float _137 = _128 - _134;
  float _138 = _129 - _135;
  float _139 = log2(_130);
  float _140 = _139 * 1.2000000476837158f;
  float _141 = _140 + 5.0f;
  float3 _142 = envMap.SampleLevel(samplerTrilinearClamp, float3(_136, _137, _138), _141);
  float2 _146 = skyContribution.Sample(samplerTrilinearClamp, float2(_23, _24));
  bool _148 = (_35 > 0.0010000000474974513f);
  float _162;
  float _163;
  float _164;
  float _165;
  if (_148) {
    float _150 = max(0.0f, _35);
    float3 _151 = miplevelMips.SampleLevel(samplerTrilinearClamp, float2(_23, _24), _150);
    float _153 = _151.x * 6.0f;
    float _154 = max(0.0f, _153);
    float3 _155 = sceneColor.SampleLevel(samplerTrilinearClamp, float2(_23, _24), _154);
    float2 _159 = skyContribution.SampleLevel(samplerTrilinearClamp, float2(_23, _24), _153);
    _162 = _155.x;
    _163 = _155.y;
    _164 = _155.z;
    _165 = (CUSTOM_WET_GROUND > 0.0f || CUSTOM_PUDDLES > 0.0f) ? SkyContributionSoft(float2(_23, _24), _153) : _159.x;
  } else {
    _162 = _29.x;
    _163 = _29.y;
    _164 = _29.z;
    _165 = (CUSTOM_WET_GROUND > 0.0f || CUSTOM_PUDDLES > 0.0f) ? SkyContributionSoft(float2(_23, _24), 0.0f) : _146.x;
  }
  float _166 = _142.x - _162;
  float _167 = _142.y - _163;
  float _168 = _142.z - _164;
  float _169 = _165 * _166;
  float _170 = _165 * _167;
  float _171 = _165 * _168;
  float _172 = _169 + _162;
  float _173 = _170 + _163;
  float _174 = _171 + _164;
  float _175 = _172 * _25.x;
  float _176 = _173 * _25.y;
  float _177 = _174 * _25.z;
  SV_Target.x = _175;
  SV_Target.y = _176;
  SV_Target.z = _177;
  SV_Target.w = _177;
  return SV_Target;
}
