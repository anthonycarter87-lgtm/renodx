// ph_billboard_lights: light bulbs/flares (runway, city, aircraft). Light Glow slider. (0xFE4BEB15)
#include "./common.hlsli"

Texture2D<float4> t0 : register(t0);

Texture2D<uint> t1 : register(t1);

Texture2D<uint> t2 : register(t2);

Texture2D<uint> t3 : register(t3);

Texture2D<float4> t4 : register(t4);

Texture2D<float4> t5 : register(t5);

Texture3D<float4> t6 : register(t6);

Texture2D<float4> t7 : register(t7);

cbuffer cb0 : register(b0) {
  struct StructGlobalConstant_Z {
    float4 StructGlobalConstant_Z_000[300];
  } CBufferGlobalConstant_Z_000 : packoffset(c000.x);
};

SamplerState s0 : register(s0);

SamplerState s1 : register(s1);

SamplerState s2 : register(s2);

float4 main(
  nointerpolation float4 LightPos : LightPos,
  nointerpolation float4 Color : Color,
  noperspective float4 SV_Position : SV_Position,
  nointerpolation float EnergyConservation : EnergyConservation,
  noperspective float2 FlareUV : FlareUV
) : SV_Target {
  float4 SV_Target;
  float _30 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].z) * SV_Position.x;
  float _31 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].w) * SV_Position.y;
  float4 _34 = t4.SampleLevel(s1, float2(_30, _31), 0.0f);
  int _36 = int(SV_Position.x);
  int _37 = int(SV_Position.y);
  uint _39 = t1.Load(int3(_36, _37, 0));
  uint _42 = t2.Load(int3(_36, _37, 0));
  uint _45 = t3.Load(int3(_36, _37, 0));
  int _47 = (uint)((int)(_42.x)) >> 19;
  int _48 = (uint)((int)(_45.x)) >> 16;
  int _49 = _47 & 15;
  bool _50 = (_49 == 9);
  int _51 = _45.x & 255;
  float _52 = float((uint)_51);
  int _53 = (uint)((int)(_45.x)) >> 8;
  int _54 = _53 & 255;
  float _55 = float((uint)_54);
  int _56 = _48 & 255;
  float _57 = float((uint)_56);
  float _58 = _52 * 0.003921568859368563f;
  float _59 = _55 * 0.003921568859368563f;
  float _60 = _57 * 0.003921568859368563f;
  float _61 = _58 * _58;
  float _62 = _59 * _59;
  float _63 = _60 * _60;
  int _64 = (uint)((int)(_45.x)) >> 24;
  float _65 = float((uint)_64);
  float _66 = _65 * 0.003921568859368563f;
  float _67 = _66 * _66;
  float _119;
  float _120;
  float _121;
  float _201;
  float _202;
  float _214;
  float _264;
  float _265;
  float _266;
  if (!_50) {
    int _69 = _39.x & 4095;
    float _70 = float((uint)_69);
    int _71 = (uint)((int)(_39.x)) >> 12;
    int _72 = _71 & 4095;
    float _73 = float((uint)_72);
    int _74 = (uint)((int)(_42.x)) >> 14;
    int _75 = _74 & 2;
    int _76 = _75 + -1;
    float _77 = float((int)(_76));
    float _78 = _70 - _73;
    float _79 = _78 * 0.00024420025874860585f;
    float _80 = _73 + _70;
    float _81 = _80 * 0.00024420025874860585f;
    float _82 = _81 + -1.0f;
    float _83 = abs(_79);
    float _84 = 1.0f - _83;
    float _85 = abs(_82);
    float _86 = _84 - _85;
    float _87 = _86 * _77;
    float _88 = dot(float3(_79, _82, _87), float3(_79, _82, _87));
    float _89 = rsqrt(_88);
    float _90 = _89 * _79;
    float _91 = _89 * _82;
    float _92 = _87 * _89;
    _119 = _90;
    _120 = _91;
    _121 = _92;
  } else {
    int _94 = _39.x & 8191;
    float _95 = float((uint)_94);
    int _96 = (uint)((int)(_39.x)) >> 13;
    int _97 = _96 & 8191;
    float _98 = float((uint)_97);
    int _99 = (uint)((int)(_39.x)) >> 25;
    int _100 = _99 & 2;
    int _101 = _100 + -1;
    float _102 = float((int)(_101));
    float _103 = _95 - _98;
    float _104 = _103 * 0.00012208521366119385f;
    float _105 = _98 + _95;
    float _106 = _105 * 0.00012208521366119385f;
    float _107 = _106 + -1.0f;
    float _108 = abs(_104);
    float _109 = 1.0f - _108;
    float _110 = abs(_107);
    float _111 = _109 - _110;
    float _112 = _111 * _102;
    float _113 = dot(float3(_104, _107, _112), float3(_104, _107, _112));
    float _114 = rsqrt(_113);
    float _115 = _114 * _104;
    float _116 = _114 * _107;
    float _117 = _112 * _114;
    _119 = _115;
    _120 = _116;
    _121 = _117;
  }
  float _134 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].x) * _119;
  float _135 = mad(_120, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].y), _134);
  float _136 = mad(_121, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].z), _135);
  float _137 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].x) * _119;
  float _138 = mad(_120, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].y), _137);
  float _139 = mad(_121, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].z), _138);
  float _140 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].x) * _119;
  float _141 = mad(_120, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].y), _140);
  float _142 = mad(_121, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].z), _141);
  float _143 = _30 * 2.0f;
  float _144 = _31 * 2.0f;
  float _145 = _143 + -1.0f;
  float _146 = 1.0f - _144;
  float _167 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].x) * _145;
  float _168 = mad(_146, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].y), _167);
  float _169 = mad(_34.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].z), _168);
  float _170 = _169 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].w);
  float _171 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].x) * _145;
  float _172 = mad(_146, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].y), _171);
  float _173 = mad(_34.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].z), _172);
  float _174 = _173 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].w);
  float _175 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].x) * _145;
  float _176 = mad(_146, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].y), _175);
  float _177 = mad(_34.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].z), _176);
  float _178 = _177 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].w);
  float _179 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].x) * _145;
  float _180 = mad(_146, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].y), _179);
  float _181 = mad(_34.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].z), _180);
  float _182 = _181 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].w);
  float _183 = _170 / _182;
  float _184 = _174 / _182;
  float _185 = _178 / _182;
  float _186 = LightPos.x - _183;
  float _187 = LightPos.y - _184;
  float _188 = LightPos.z - _185;
  float _189 = dot(float3(_186, _187, _188), float3(_186, _187, _188));
  int _192 = asint((CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[6].w));
  bool _193 = (_192 == 2);
  if (_193) {
    float _198 = _30 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].z);
    float _199 = _31 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].w);
    _201 = _198;
    _202 = _199;
  } else {
    _201 = _30;
    _202 = _31;
  }
  float4 _205 = t5.SampleLevel(s2, float2(_201, _202), 0.0f);
  uint _207 = 1 << _49;
  int _208 = _207 & 104;
  bool _209 = (_208 == 0);
  if (!_209) {
    float _211 = _205.x + 0.25f;
    float _212 = saturate(_211);
    _214 = _212;
  } else {
    _214 = _205.x;
  }
  bool _215 = (Color.w > 0.0f);
  bool _216 = (_189 < LightPos.w);
  bool _217 = _215 && _216;
  if (_217) {
    float _219 = _189 + 1.0f;
    float _220 = 1.0f / _219;
    float _221 = _189 / LightPos.w;
    float _222 = 1.0f - _221;
    float _223 = saturate(_222);
    float _224 = _223 * _220;
    float _225 = rsqrt(_189);
    float _226 = _225 * _186;
    float _227 = _225 * _187;
    float _228 = _225 * _188;
    float _229 = dot(float3(_136, _139, _142), float3(_226, _227, _228));
    float _230 = saturate(_229);
    float _231 = abs(_229);
    float _232 = 1.0f - _231;
    float _233 = _232 * 0.25f;
    float _234 = _233 + _230;
    float _235 = Color.x * 0.31830987334251404f;
    float _236 = _235 * _61;
    float _237 = _236 * _214;
    float _238 = _237 * _224;
    float _239 = _238 * _234;
    float _240 = Color.y * 0.31830987334251404f;
    float _241 = _240 * _62;
    float _242 = _241 * _214;
    float _243 = _242 * _224;
    float _244 = _243 * _234;
    float _245 = Color.z * 0.31830987334251404f;
    float _246 = _245 * _63;
    float _247 = _246 * _214;
    float _248 = _247 * _224;
    float _249 = _248 * _234;
    int _250 = _42.x & 8388608;
    bool _251 = (_250 == 0);
    if (_251) {
      float _253 = _67 + -0.5f;
      float _254 = _253 * 2.0f;
      float _255 = saturate(_254);
      float _256 = _255 * 2.0f;
      float _257 = 3.0f - _256;
      float _258 = _255 * _255;
      float _259 = _258 * _257;
      float _260 = _259 * _239;
      float _261 = _259 * _244;
      float _262 = _259 * _249;
      _264 = _260;
      _265 = _261;
      _266 = _262;
    } else {
      _264 = _239;
      _265 = _244;
      _266 = _249;
    }
  } else {
    _264 = 0.0f;
    _265 = 0.0f;
    _266 = 0.0f;
  }
  float _267 = _183 * _183;
  float _268 = _184 * _184;
  float _269 = _268 + _267;
  float _270 = _185 * _185;
  float _271 = _269 + _270;
  float _272 = sqrt(_271);
  float _273 = _272 * 1.9999999494757503e-05f;
  float _274 = sqrt(_273);
  float _275 = _274 + -0.0078125f;
  float4 _278 = t6.SampleLevel(s0, float3(_30, _31, _275), 0.0f);
  float _280 = _272 * 0.08191999793052673f;
  float _281 = saturate(_280);
  float _282 = _278.x + -1.0f;
  float _283 = _282 * _281;
  float _284 = _283 + 1.0f;
  float _285 = _284 * _284;
  float _286 = _285 * _264;
  float _287 = _285 * _265;
  float _288 = _285 * _266;
  float _289 = Color.x * EnergyConservation;
  float _290 = Color.y * EnergyConservation;
  float _291 = Color.z * EnergyConservation;
  float4 _293 = t0.Load(int3(0, 0, 0));
  float _295 = LightPos.x * LightPos.x;
  float _296 = LightPos.y * LightPos.y;
  float _297 = _296 + _295;
  float _298 = LightPos.z * LightPos.z;
  float _299 = _297 + _298;
  float _300 = sqrt(_299);
  float _301 = _300 + -200.0f;
  float _302 = _301 * 0.0020000000949949026f;
  float _303 = saturate(_302);
  float _304 = 2.5f / _300;
  float _305 = _304 + 1.0f;
  float _306 = dot(float2(LightPos.x, LightPos.y), float2(LightPos.x, LightPos.y));
  float _307 = rsqrt(_306);
  float _308 = _307 * LightPos.x;
  float _309 = _307 * LightPos.y;
  float _310 = dot(float2(FlareUV.x, FlareUV.y), float2(FlareUV.x, FlareUV.y));
  float _311 = rsqrt(_310);
  float _312 = _311 * FlareUV.x;
  float _313 = _311 * FlareUV.y;
  float _314 = dot(float2(_308, _309), float2(_312, _313));
  float _315 = abs(_314);
  float _316 = _315 * 0.699999988079071f;
  float _317 = _316 + 0.4000000059604645f;
  float _318 = _305 * FlareUV.x;
  float _319 = _305 * FlareUV.y;
  float _320 = _318 + 2.5f;
  float _321 = _319 + 2.5f;
  float _322 = _320 * 0.009999999776482582f;
  float _323 = _321 * 0.009999999776482582f;
  float _324 = _322 + 0.4749999940395355f;
  float _325 = _323 + 0.4749999940395355f;
  float _326 = saturate(_310);
  float _327 = 1.0f - _326;
  float4 _330 = t7.Sample(s0, float2(_324, _325));
  float _333 = _303 * 2.0f;
  float _334 = 2.5f - _333;
  float _335 = _293.x * 6.665999889373779f;
  float _336 = saturate(_335);
  float _337 = _330.y * _317;
  float _338 = _337 * _336;
  float _339 = _338 + _330.x;
  float _340 = _334 * _339;
  float _341 = _340 * 0.11999999731779099f;
  float _342 = log2(_341);
  float _343 = _342 * 4.5f;
  float _344 = exp2(_343);
  float _345 = 1.0f - _303;
  float _346 = _344 * _345;
  float _347 = _327 * _327;
  float _348 = _347 * _303;
  float _349 = _348 * _327;
  float _350 = _346 + _349;
  float _351 = Color.w + -0.10000000149011612f;
  float _352 = max(0.0f, _351);
  float _353 = _289 * _352;
  float _354 = _353 * _350;
  float _355 = _290 * _352;
  float _356 = _355 * _350;
  float _357 = _291 * _352;
  float _358 = _357 * _350;
  float _359 = _354 + _286;
  float _360 = _356 + _287;
  float _361 = _358 + _288;
  float _364 = _359 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  float _365 = _360 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  float _366 = _361 * (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_GLOW);
  SV_Target.x = _364;
  SV_Target.y = _365;
  SV_Target.z = _366;
  SV_Target.w = _285;
  return SV_Target;
}
