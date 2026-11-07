// FS25 XeGTAO temporal accumulation: blends this frame's raw AO with last frame's final AO.
// The AO Strength slider is applied to this frame's samples only (last frame's AO already has it), so the extra
// power is applied once and never compounds through the history.
#include "./shared.h"

float ApplyAOStrength(float visibility) {
  return (CUSTOM_AO_STRENGTH == 0.f) ? 1.f : pow(visibility, CUSTOM_AO_STRENGTH);
}

Texture2D<float> g_srcWorkingDepth : register(t0);

Texture2D<float2> g_motionVector : register(t1);

Texture2D<uint> g_srcWorkingAOTerm : register(t2);

Texture2D<uint> g_prevAOTerm : register(t3);

Texture2D<float> g_prevLinearDepth : register(t4);

Texture2D<float> g_srcWorkingEdges : register(t5);

RWTexture2D<uint> g_outWorkingAOTerm : register(u0);

cbuffer GTAOParams : register(b0) {
  float2 gCst_iViewportSize : packoffset(c000.x);
  float2 gCst_ViewportPixelSize : packoffset(c000.z);
  float2 gCst_DepthUnpackConsts : packoffset(c001.x);
  float2 gCst_CameraTanHalfFOV : packoffset(c001.z);
  float2 gCst_NDCToViewMul : packoffset(c002.x);
  float2 gCst_NDCToViewAdd : packoffset(c002.z);
  float2 gCst_NDCToViewMul_x_PixelSize : packoffset(c003.x);
  float gCst_EffectRadius : packoffset(c003.z);
  float gCst_EffectFalloffRange : packoffset(c003.w);
  float gCst_RadiusMultiplier : packoffset(c004.x);
  float gCst_iMipOffset : packoffset(c004.y);
  float gCst_FinalValuePower : packoffset(c004.z);
  float gCst_DenoiseBlurBeta : packoffset(c004.w);
  float gCst_SampleDistributionPower : packoffset(c005.x);
  float gCst_ThinOccluderCompensation : packoffset(c005.y);
  float gCst_DepthMIPSamplingOffset : packoffset(c005.z);
  float gCst_iNoiseIndex : packoffset(c005.w);
  float gCst_farNDCz : packoffset(c006.x);
  float gCst_msaaSampleCount : packoffset(c006.y);
};

cbuffer GTAOTemporalParams : register(b1) {
  row_major float4x4 g_reProjection : packoffset(c000.x);
  float g_nearClip : packoffset(c004.x);
  float g_iNormalMapScale : packoffset(c004.y);
  float g_iNumSamples : packoffset(c004.z);
};

[numthreads(8, 8, 1)]
void main(
  uint3 SV_DispatchThreadID : SV_DispatchThreadID,
  uint3 SV_GroupID : SV_GroupID,
  uint3 SV_GroupThreadID : SV_GroupThreadID,
  uint SV_GroupIndex : SV_GroupIndex
) {
  int _14 = asint(gCst_iMipOffset);
  int _17 = asint(g_iNormalMapScale);
  float _18 = float((uint)SV_DispatchThreadID.x);
  float _19 = float((uint)SV_DispatchThreadID.y);
  float _20 = _18 + 0.5f;
  float _21 = _19 + 0.5f;
  float _25 = gCst_ViewportPixelSize.x * _20;
  float _26 = gCst_ViewportPixelSize.y * _21;
  float _27 = g_srcWorkingDepth.Load(int3((uint)(SV_DispatchThreadID.x), (uint)(SV_DispatchThreadID.y), _14));
  uint _29 = _17 * (uint)(SV_DispatchThreadID.x);
  uint _30 = _17 * (uint)(SV_DispatchThreadID.y);
  float2 _31 = g_motionVector.Load(int3(_29, _30, 0));
  float _34 = _31.x * 0.5f;
  float _35 = _31.y * 0.5f;
  float _36 = _25 - _34;
  float _37 = _35 + _26;
  uint _38 = g_srcWorkingAOTerm.Load(int3((uint)(SV_DispatchThreadID.x), (uint)(SV_DispatchThreadID.y), 0));
  float _40 = float((uint)(int)(_38.x));
  float _41 = ApplyAOStrength(_40 * 0.003921568859368563f);
  float _42 = saturate(_36);
  float _43 = saturate(_37);
  bool _44 = (_36 == _42);
  bool _45 = (_37 == _43);
  bool _46 = _44 && _45;
  float _175;
  if (_46) {
    uint2 _48; g_prevAOTerm.GetDimensions(_48.x, _48.y);
    float _51 = float((uint)_48.x);
    float _52 = float((uint)_48.y);
    float _53 = _51 * _36;
    float _54 = _52 * _37;
    int _55 = int(_53);
    int _56 = int(_54);
    float _57 = g_prevLinearDepth.Load(int3(_55, _56, _14));
    float _59 = _27.x - _57.x;
    float _60 = abs(_59);
    float _61 = _60 + -0.25f;
    float _62 = saturate(_61);
    float _63 = _62 * 4.0f;
    float _64 = 1.0f - _63;
    float _65 = saturate(_64);
    float _66 = g_srcWorkingEdges.Load(int3((uint)(SV_DispatchThreadID.x), (uint)(SV_DispatchThreadID.y), 0));
    float _68 = _66.x * 255.5f;
    uint _69 = uint(_68);
    int _70 = (uint)(_69) >> 6;
    int _71 = _70 & 3;
    float _72 = float((uint)_71);
    float _73 = _72 * 0.3333333432674408f;
    int _74 = (uint)(_69) >> 4;
    int _75 = _74 & 3;
    float _76 = float((uint)_75);
    float _77 = _76 * 0.3333333432674408f;
    int _78 = (uint)(_69) >> 2;
    int _79 = _78 & 3;
    float _80 = float((uint)_79);
    float _81 = _80 * 0.3333333432674408f;
    int _82 = _69 & 3;
    float _83 = float((uint)_82);
    float _84 = _83 * 0.3333333432674408f;
    float _85 = saturate(_73);
    float _86 = saturate(_77);
    float _87 = saturate(_81);
    float _88 = saturate(_84);
    float _89 = _86 * _85;
    float _90 = _89 * _87;
    float _91 = _90 * _88;
    float _92 = _27.x + -4.0f;
    float _93 = saturate(_92);
    float _94 = 1.0f - _91;
    float _95 = _94 * _93;
    float _96 = _95 + _91;
    uint _97 = g_prevAOTerm.Load(int3(_55, _56, 0));
    float _99 = float((uint)(int)(_97.x));
    float _100 = _99 * 0.003921568859368563f;
    uint _101 = SV_DispatchThreadID.x + -1u;
    uint _102 = SV_DispatchThreadID.y + -1u;
    int _103 = max(_101, 0);
    int _104 = max(_102, 0);
    uint _105 = g_srcWorkingAOTerm.Load(int3(_103, _104, 0));
    float _107 = float((uint)(int)(_105.x));
    float _108 = ApplyAOStrength(_107 * 0.003921568859368563f);
    float _109 = min(_108, _41);
    float _110 = max(_108, _41);
    int _111 = max((uint)(SV_DispatchThreadID.x), 0);
    uint _112 = g_srcWorkingAOTerm.Load(int3(_111, _104, 0));
    float _114 = float((uint)(int)(_112.x));
    float _115 = ApplyAOStrength(_114 * 0.003921568859368563f);
    float _116 = min(_115, _109);
    float _117 = max(_115, _110);
    uint _118 = SV_DispatchThreadID.x + 1u;
    int _119 = max(_118, 0);
    uint _120 = g_srcWorkingAOTerm.Load(int3(_119, _104, 0));
    float _122 = float((uint)(int)(_120.x));
    float _123 = ApplyAOStrength(_122 * 0.003921568859368563f);
    float _124 = min(_123, _116);
    float _125 = max(_123, _117);
    int _126 = max((uint)(SV_DispatchThreadID.y), 0);
    uint _127 = g_srcWorkingAOTerm.Load(int3(_103, _126, 0));
    float _129 = float((uint)(int)(_127.x));
    float _130 = ApplyAOStrength(_129 * 0.003921568859368563f);
    float _131 = min(_130, _124);
    float _132 = max(_130, _125);
    uint _133 = g_srcWorkingAOTerm.Load(int3(_119, _126, 0));
    float _135 = float((uint)(int)(_133.x));
    float _136 = ApplyAOStrength(_135 * 0.003921568859368563f);
    float _137 = min(_136, _131);
    float _138 = max(_136, _132);
    uint _139 = SV_DispatchThreadID.y + 1u;
    int _140 = max(_139, 0);
    uint _141 = g_srcWorkingAOTerm.Load(int3(_103, _140, 0));
    float _143 = float((uint)(int)(_141.x));
    float _144 = ApplyAOStrength(_143 * 0.003921568859368563f);
    float _145 = min(_144, _137);
    float _146 = max(_144, _138);
    uint _147 = g_srcWorkingAOTerm.Load(int3(_111, _140, 0));
    float _149 = float((uint)(int)(_147.x));
    float _150 = ApplyAOStrength(_149 * 0.003921568859368563f);
    float _151 = min(_150, _145);
    float _152 = max(_150, _146);
    uint _153 = g_srcWorkingAOTerm.Load(int3(_119, _140, 0));
    float _155 = float((uint)(int)(_153.x));
    float _156 = ApplyAOStrength(_155 * 0.003921568859368563f);
    float _157 = min(_156, _151);
    float _158 = max(_156, _152);
    float _159 = _158 + _157;
    float _160 = _159 * 0.5f;
    float _161 = _160 - _157;
    float _162 = _161 * 0.5f;
    float _163 = _162 + _157;
    float _164 = _160 - _158;
    float _165 = _164 * 0.5f;
    float _166 = _165 + _158;
    float _167 = max(_100, _163);
    float _168 = min(_167, _166);
    float _169 = _65 * 0.8999999761581421f;
    float _170 = _169 * _96;
    float _171 = _168 - _41;
    float _172 = _170 * _171;
    float _173 = _172 + _41;
    _175 = _173;
  } else {
    _175 = _41;
  }
  float _176 = _175 * 0.6666666865348816f;
  float _177 = saturate(_176);
  float _178 = _177 * 255.0f;
  float _179 = _178 + 0.5f;
  uint _180 = uint(_179);
  g_outWorkingAOTerm[int2((uint)(SV_DispatchThreadID.x), (uint)(SV_DispatchThreadID.y))] = _180;
}
