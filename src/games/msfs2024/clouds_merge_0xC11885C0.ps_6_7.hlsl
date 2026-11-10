// ph_volumetric_clouds_merge (0xC11885C0): composites the volumetric clouds. v1.1 test: Cloud Brightness.
#include "./common.hlsli"

Texture2D<float4> t0 : register(t0);

Texture2DArray<float4> t1 : register(t1);

Texture2DArray<float4> t2 : register(t2);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t4 : register(t4);

Texture2D<float4> t5 : register(t5);

Texture2D<float4> t6 : register(t6);

cbuffer cb1 : register(b1) {
  struct StructGlobalConstant_Z {
    float4 StructGlobalConstant_Z_000[300];
  } CBufferGlobalConstant_Z_000 : packoffset(c000.x);
};

cbuffer cb0 : register(b0) {
  struct StructUserConstant_Z {
    float4 StructUserConstant_Z_000[658];
  } CBufferUserConstant_Z_000 : packoffset(c000.x);
};

SamplerState s0 : register(s0);

SamplerState s1 : register(s1);

struct OutputSignature {
  float4 SV_Target : SV_Target;
  float4 SV_Target_1 : SV_Target1;
  float4 SV_Target_2 : SV_Target2;
};

OutputSignature main(
  linear float4 TEXCOORD : TEXCOORD,
  noperspective float4 SV_Position : SV_Position,
  nointerpolation uint INSTANCE_ID : INSTANCE_ID
) {
  float4 SV_Target;
  float4 SV_Target_1;
  float4 SV_Target_2;
  uint _16 = uint(SV_Position.x);
  uint _17 = uint(SV_Position.y);
  float4 _19 = t3.Load(int3(_16, _17, 0));
  float4 _25 = t4.Load(int3(_16, _17, 0));
  int _32 = asint((CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[6].w));
  bool _33 = (_32 == 2);
  float _134;
  float _135;
  float _136;
  float _137;
  float _138;
  float _139;
  float _140;
  float _141;
  [branch]
  if (_33) {
    float _38 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].z) * SV_Position.x;
    float _39 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].w) * SV_Position.y;
    float _43 = _38 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].z);
    float _44 = _39 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].w);
    float4 _47 = t3.SampleLevel(s1, float2(_43, _44), 0.0f);
    float4 _53 = t4.SampleLevel(s1, float2(_43, _44), 0.0f);
    float4 _60 = t0.GatherRed(s0, float2(_43, _44));
    float _65 = max(_60.y, _60.z);
    float _66 = max(_60.x, _65);
    float _67 = max(_66, _60.w);
    float4 _69 = t5.GatherRed(s1, float2(_43, _44));
    float _74 = max(_69.y, _69.z);
    float _75 = max(_69.x, _74);
    float _76 = max(_75, _69.w);
    float4 _78 = t6.GatherRed(s1, float2(_43, _44));
    float _83 = max(_78.y, _78.z);
    float _84 = max(_78.x, _83);
    float _85 = max(_84, _78.w);
    float _89 = _67 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[168].z);
    float _90 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[168].w) / _89;
    float _91 = min(_90, _76);
    float _92 = _91 * 0.006000000052154064f;
    float _93 = _92 + 10.0f;
    float _96 = min(_93, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[51].w));
    float _97 = min(_90, _85);
    float _98 = _97 * 0.006000000052154064f;
    float _99 = _98 + 10.0f;
    float _100 = min(_99, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[51].w));
    float _101 = _90 - _76;
    float _102 = _101 + _96;
    float _103 = _102 / _96;
    float _104 = saturate(_103);
    float _105 = _90 - _85;
    float _106 = _105 + _100;
    float _107 = _106 / _100;
    float _108 = saturate(_107);
    float _109 = _47.x - _19.x;
    float _110 = _47.y - _19.y;
    float _111 = _47.z - _19.z;
    float _112 = _47.w - _19.w;
    float _113 = _104 * _109;
    float _114 = _104 * _110;
    float _115 = _104 * _111;
    float _116 = _104 * _112;
    float _117 = _113 + _19.x;
    float _118 = _114 + _19.y;
    float _119 = _115 + _19.z;
    float _120 = _116 + _19.w;
    float _121 = _53.x - _25.x;
    float _122 = _53.y - _25.y;
    float _123 = _53.z - _25.z;
    float _124 = _53.w - _25.w;
    float _125 = _108 * _121;
    float _126 = _108 * _122;
    float _127 = _108 * _123;
    float _128 = _108 * _124;
    float _129 = _125 + _25.x;
    float _130 = _126 + _25.y;
    float _131 = _127 + _25.z;
    float _132 = _128 + _25.w;
    _134 = _117;
    _135 = _118;
    _136 = _119;
    _137 = _120;
    _138 = _129;
    _139 = _130;
    _140 = _131;
    _141 = _132;
  } else {
    _134 = _19.x;
    _135 = _19.y;
    _136 = _19.z;
    _137 = _19.w;
    _138 = _25.x;
    _139 = _25.y;
    _140 = _25.z;
    _141 = _25.w;
  }
  float _142 = 1.0f - _141;
  float _143 = _142 * _134;
  float _144 = _142 * _135;
  float _145 = _142 * _136;
  float _146 = _142 * _137;
  float _147 = _143 + _138;
  float _148 = _144 + _139;
  float _149 = _145 + _140;
  float _150 = _146 + _141;
  float _151 = _150 * 1.0204081535339355f;
  float _152 = saturate(_151);
  float _155 = _147 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].y);
  float _156 = _148 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].y);
  float _157 = _149 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].y);
  float _160 = (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z) * (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z);
  float _161 = _160 * _155;
  float _162 = (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z) * (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z);
  float _163 = _162 * _156;
  float _164 = (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z) * (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z);
  float _165 = _164 * _157;
  float _166 = (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z) * (CBufferUserConstant_Z_000.StructUserConstant_Z_000[0].z);
  float _167 = _166 * _152;
  SV_Target_2.x = _167;
  SV_Target_2.y = 0.0f;
  SV_Target_2.z = 0.0f;
  SV_Target_2.w = 1.0f;
  float _168 = _167 * 8.0f;
  SV_Target_1.x = _168;
  SV_Target_1.y = 0.0f;
  SV_Target_1.z = 0.0f;
  SV_Target_1.w = 0.0f;
  float _171 = _161 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_CLOUD_BRIGHTNESS);  // RenoDX: Cloud Brightness
  float _172 = _163 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_CLOUD_BRIGHTNESS);  // RenoDX: Cloud Brightness
  float _173 = _165 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_CLOUD_BRIGHTNESS);  // RenoDX: Cloud Brightness
  int _176 = asint((CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[295].w));
  bool _177 = (_176 != 0);
  float _178 = log2(_171);
  float _179 = log2(_172);
  float _180 = log2(_173);
  float _181 = floor(_178);
  float _182 = floor(_179);
  float _183 = floor(_180);
  float _184 = _181 + -6.0f;
  float _185 = _182 + -6.0f;
  float _186 = _183 + -5.0f;
  float _187 = exp2(_184);
  float _188 = exp2(_185);
  float _189 = exp2(_186);
  bool _190 = (_171 <= 0.0f);
  bool _191 = (_172 <= 0.0f);
  bool _192 = (_173 <= 0.0f);
  float _193 = select(_190, 0.0f, _187);
  float _194 = select(_191, 0.0f, _188);
  float _195 = select(_192, 0.0f, _189);
  int _198 = asint((CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[1].w));
  int _199 = select(_177, _198, 0);
  int _200 = _16 & 63;
  int _201 = _17 & 63;
  float4 _203 = t1.Load(int4(_200, _201, _199, 0));
  float4 _206 = t2.Load(int4(_200, _201, _199, 0));
  float _209 = _203.x * 2.0f;
  float _210 = _206.x * 2.0f;
  float _211 = _206.y * 2.0f;
  float _212 = _209 + -1.0f;
  float _213 = _210 + -1.0f;
  float _214 = _211 + -1.0f;
  float _215 = abs(_212);
  float _216 = abs(_213);
  float _217 = abs(_214);
  float _218 = 1.0f - _215;
  float _219 = 1.0f - _216;
  float _220 = 1.0f - _217;
  float _221 = sqrt(_218);
  float _222 = sqrt(_219);
  float _223 = sqrt(_220);
  float _224 = 1.0f - _221;
  float _225 = 1.0f - _222;
  float _226 = 1.0f - _223;
  bool _227 = (_212 >= 0.0f);
  float _228 = select(_227, 1.0f, -1.0f);
  bool _229 = (_213 >= 0.0f);
  float _230 = select(_229, 1.0f, -1.0f);
  bool _231 = (_214 >= 0.0f);
  float _232 = select(_231, 1.0f, -1.0f);
  float _233 = _228 * _193;
  float _234 = _233 * _224;
  float _235 = _230 * _194;
  float _236 = _235 * _225;
  float _237 = _232 * _195;
  float _238 = _237 * _226;
  float _239 = _234 + _171;
  float _240 = _236 + _172;
  float _241 = _238 + _173;
  SV_Target.x = _239;
  SV_Target.y = _240;
  SV_Target.z = _241;
  SV_Target.w = _167;
  OutputSignature output_signature = { SV_Target, SV_Target_1, SV_Target_2 };
  return output_signature;
}
