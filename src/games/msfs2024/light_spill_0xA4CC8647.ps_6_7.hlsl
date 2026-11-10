// ph_macro_lights: light cast onto the ground/scene by night lights. Light Spill slider. (0xA4CC8647)
#include "./common.hlsli"

Texture2D<uint> t0 : register(t0);

Texture2D<uint> t1 : register(t1);

Texture2D<uint> t2 : register(t2);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t4 : register(t4);

cbuffer cb0 : register(b0) {
  struct StructGlobalConstant_Z {
    float4 StructGlobalConstant_Z_000[300];
  } CBufferGlobalConstant_Z_000 : packoffset(c000.x);
};

SamplerState s0 : register(s0);

SamplerState s1 : register(s1);

float3 main(
  noperspective float4 SV_Position : SV_Position,
  nointerpolation float3 LIGHTPOS : LIGHTPOS,
  nointerpolation float RADIUSSQR : RADIUSSQR,
  nointerpolation float3 INTENSITY : INTENSITY,
  nointerpolation float CONE : CONE,
  nointerpolation float3 LIGHTDIR : LIGHTDIR,
  nointerpolation uint SYMMETRY : SYMMETRY,
  nointerpolation uint INSTANCE_ID : INSTANCE_ID
) : SV_Target {
  float3 SV_Target;
  bool _11 = (SYMMETRY == 0);
  float _28 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].z) * SV_Position.x;
  float _29 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[105].w) * SV_Position.y;
  float _30 = _28 * 2.0f;
  float _31 = _29 * 2.0f;
  float _32 = _30 + -1.0f;
  float _33 = 1.0f - _31;
  float4 _36 = t3.SampleLevel(s0, float2(_28, _29), 0.0f);
  int _38 = int(SV_Position.x);
  int _39 = int(SV_Position.y);
  uint _41 = t0.Load(int3(_38, _39, 0));
  uint _44 = t1.Load(int3(_38, _39, 0));
  uint _47 = t2.Load(int3(_38, _39, 0));
  int _49 = (uint)((int)(_47.x)) >> 16;
  int _50 = (uint)((int)(_44.x)) >> 19;
  int _51 = _50 & 15;
  bool _52 = (_51 == 9);
  int _53 = _44.x & 255;
  float _54 = float((uint)_53);
  float _55 = _54 * 0.003921568859368563f;
  int _56 = _47.x & 255;
  float _57 = float((uint)_56);
  int _58 = (uint)((int)(_47.x)) >> 8;
  int _59 = _58 & 255;
  float _60 = float((uint)_59);
  int _61 = _49 & 255;
  float _62 = float((uint)_61);
  float _63 = _57 * 0.003921568859368563f;
  float _64 = _60 * 0.003921568859368563f;
  float _65 = _62 * 0.003921568859368563f;
  float _66 = _63 * _63;
  float _67 = _64 * _64;
  float _68 = _65 * _65;
  int _69 = (uint)((int)(_47.x)) >> 24;
  float _70 = float((uint)_69);
  float _71 = _70 * 0.003921568859368563f;
  float _72 = _71 * _71;
  float _117;
  float _118;
  float _195;
  float _196;
  float _197;
  float _198;
  float _199;
  float _200;
  float _201;
  float _352;
  float _368;
  float _369;
  float _381;
  float _420;
  float _421;
  float _422;
  if (!_52) {
    int _74 = _44.x & 458752;
    bool _75 = (_74 == 65536);
    int _76 = _41.x & 4095;
    float _77 = float((uint)_76);
    int _78 = (uint)((int)(_41.x)) >> 12;
    int _79 = _78 & 4095;
    float _80 = float((uint)_79);
    int _81 = (uint)((int)(_44.x)) >> 14;
    int _82 = _81 & 2;
    int _83 = _82 + -1;
    float _84 = float((int)(_83));
    float _85 = _77 - _80;
    float _86 = _85 * 0.00024420025874860585f;
    float _87 = _80 + _77;
    float _88 = _87 * 0.00024420025874860585f;
    float _89 = _88 + -1.0f;
    float _90 = abs(_86);
    float _91 = 1.0f - _90;
    float _92 = abs(_89);
    float _93 = _91 - _92;
    float _94 = _93 * _84;
    float _95 = dot(float3(_86, _89, _94), float3(_86, _89, _94));
    float _96 = rsqrt(_95);
    float _97 = _96 * _86;
    float _98 = _96 * _89;
    float _99 = _94 * _96;
    int _100 = (uint)((int)(_41.x)) >> 24;
    float _101 = float((uint)_100);
    int _102 = (uint)((int)(_44.x)) >> 8;
    int _103 = _102 & 127;
    float _104 = float((uint)_103);
    float _105 = _104 * 0.007874015718698502f;
    float _106 = select(_75, 0.0f, _105);
    int _107 = _50 & 14;
    bool _108 = (_107 == 6);
    if (_108) {
      float _110 = _101 * 0.003921568859368563f;
      bool _111 = (_110 < 0.5f);
      float _112 = _101 * 0.007843137718737125f;
      float _113 = _112 + -1.0f;
      if (_111) {
        float _115 = abs(_113);
        _117 = _55;
        _118 = _115;
      } else {
        _117 = _113;
        _118 = _55;
      }
      float _119 = min(_118, _117);
      float _120 = _119 * 2.0f;
      float _121 = _120 + -1.0f;
      float _122 = saturate(_121);
      float _123 = _122 * 0.03999999910593033f;
      float _124 = 0.03999999910593033f - _123;
      float _125 = _66 - _124;
      float _126 = _67 - _124;
      float _127 = _68 - _124;
      float _128 = _125 * _106;
      float _129 = _126 * _106;
      float _130 = _127 * _106;
      float _131 = _128 + _124;
      float _132 = _129 + _124;
      float _133 = _130 + _124;
      _195 = _97;
      _196 = _98;
      _197 = _99;
      _198 = _131;
      _199 = _132;
      _200 = _133;
      _201 = _118;
    } else {
      bool _165 = (_51 == 2);
      float _166 = _54 * 0.007843137718737125f;
      float _167 = _166 + -1.0f;
      float _168 = saturate(_167);
      float _169 = _168 * 0.03999999910593033f;
      float _170 = 0.03999999910593033f - _169;
      if (_165) {
        float _172 = sqrt(_66);
        float _173 = sqrt(_67);
        float _174 = sqrt(_68);
        float _175 = _172 - _170;
        float _176 = _173 - _170;
        float _177 = _174 - _170;
        float _178 = _175 * _106;
        float _179 = _176 * _106;
        float _180 = _177 * _106;
        float _181 = _178 + _170;
        float _182 = _179 + _170;
        float _183 = _180 + _170;
        _195 = _97;
        _196 = _98;
        _197 = _99;
        _198 = _181;
        _199 = _182;
        _200 = _183;
        _201 = _55;
      } else {
        float _185 = _66 - _170;
        float _186 = _67 - _170;
        float _187 = _68 - _170;
        float _188 = _185 * _106;
        float _189 = _186 * _106;
        float _190 = _187 * _106;
        float _191 = _188 + _170;
        float _192 = _189 + _170;
        float _193 = _190 + _170;
        _195 = _97;
        _196 = _98;
        _197 = _99;
        _198 = _191;
        _199 = _192;
        _200 = _193;
        _201 = _55;
      }
    }
  } else {
    int _135 = _41.x & 8191;
    float _136 = float((uint)_135);
    int _137 = (uint)((int)(_41.x)) >> 13;
    int _138 = _137 & 8191;
    float _139 = float((uint)_138);
    int _140 = (uint)((int)(_41.x)) >> 25;
    int _141 = _140 & 2;
    int _142 = _141 + -1;
    float _143 = float((int)(_142));
    float _144 = _136 - _139;
    float _145 = _144 * 0.00012208521366119385f;
    float _146 = _139 + _136;
    float _147 = _146 * 0.00012208521366119385f;
    float _148 = _147 + -1.0f;
    float _149 = abs(_145);
    float _150 = 1.0f - _149;
    float _151 = abs(_148);
    float _152 = _150 - _151;
    float _153 = _152 * _143;
    float _154 = dot(float3(_145, _148, _153), float3(_145, _148, _153));
    float _155 = rsqrt(_154);
    float _156 = _155 * _145;
    float _157 = _155 * _148;
    float _158 = _153 * _155;
    float _159 = _54 * 0.007843137718737125f;
    float _160 = _159 + -1.0f;
    float _161 = saturate(_160);
    float _162 = _161 * 0.03999999910593033f;
    float _163 = 0.03999999910593033f - _162;
    _195 = _156;
    _196 = _157;
    _197 = _158;
    _198 = _163;
    _199 = _163;
    _200 = _163;
    _201 = _55;
  }
  float _222 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].x) * _32;
  float _223 = mad(_33, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].y), _222);
  float _224 = mad(_36.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].z), _223);
  float _225 = _224 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[174].w);
  float _226 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].x) * _32;
  float _227 = mad(_33, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].y), _226);
  float _228 = mad(_36.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].z), _227);
  float _229 = _228 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[175].w);
  float _230 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].x) * _32;
  float _231 = mad(_33, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].y), _230);
  float _232 = mad(_36.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].z), _231);
  float _233 = _232 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[176].w);
  float _234 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].x) * _32;
  float _235 = mad(_33, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].y), _234);
  float _236 = mad(_36.x, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].z), _235);
  float _237 = _236 + (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[177].w);
  float _238 = _225 / _237;
  float _239 = _229 / _237;
  float _240 = _233 / _237;
  float _241 = LIGHTPOS.x - _238;
  float _242 = LIGHTPOS.y - _239;
  float _243 = LIGHTPOS.z - _240;
  float _244 = dot(float3(_241, _242, _243), float3(_241, _242, _243));
  bool _245 = (_244 < RADIUSSQR);
  bool _246 = (RADIUSSQR > 0.0f);
  bool _247 = _246 && _245;
  if (_247) {
    float _261 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].x) * _195;
    float _262 = mad(_196, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].y), _261);
    float _263 = mad(_197, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[134].z), _262);
    float _264 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].x) * _195;
    float _265 = mad(_196, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].y), _264);
    float _266 = mad(_197, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[135].z), _265);
    float _267 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].x) * _195;
    float _268 = mad(_196, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].y), _267);
    float _269 = mad(_197, (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[136].z), _268);
    float _270 = dot(float3(_238, _239, _240), float3(_238, _239, _240));
    float _271 = rsqrt(_270);
    float _272 = _271 * _238;
    float _273 = _271 * _239;
    float _274 = _271 * _240;
    float _275 = -0.0f - _272;
    float _276 = -0.0f - _273;
    float _277 = -0.0f - _274;
    float _278 = rsqrt(_244);
    float _279 = _278 * _241;
    float _280 = _278 * _242;
    float _281 = _278 * _243;
    float _282 = _244 + 1.0f;
    float _283 = 1.0f / _282;
    float _284 = _244 / RADIUSSQR;
    float _285 = 1.0f - _284;
    float _286 = saturate(_285);
    float _287 = max(0.07999999821186066f, _201);
    float _288 = _279 - _272;
    float _289 = _280 - _273;
    float _290 = _281 - _274;
    float _291 = dot(float3(_288, _289, _290), float3(_288, _289, _290));
    float _292 = rsqrt(_291);
    float _293 = _292 * _288;
    float _294 = _292 * _289;
    float _295 = _292 * _290;
    float _296 = dot(float3(_263, _266, _269), float3(_275, _276, _277));
    float _297 = abs(_296);
    float _298 = dot(float3(_293, _294, _295), float3(_279, _280, _281));
    float _299 = saturate(_298);
    float _300 = dot(float3(_263, _266, _269), float3(_293, _294, _295));
    float _301 = saturate(_300);
    float _302 = dot(float3(_263, _266, _269), float3(_279, _280, _281));
    float _303 = saturate(_302);
    float _304 = 1.0f - _198;
    float _305 = 1.0f - _199;
    float _306 = 1.0f - _200;
    float _307 = 1.0f - _299;
    float _308 = _307 * _307;
    float _309 = _308 * _308;
    float _310 = _309 * _307;
    float _311 = _310 * _304;
    float _312 = _310 * _305;
    float _313 = _310 * _306;
    float _314 = _311 + _198;
    float _315 = _312 + _199;
    float _316 = _313 + _200;
    float _317 = _287 * _287;
    float _318 = _317 * _317;
    float _319 = _301 * _318;
    float _320 = _319 - _301;
    float _321 = _320 * _301;
    float _322 = _321 + 1.0f;
    float _323 = _322 * _322;
    float _324 = _323 * 3.1415927410125732f;
    float _325 = _318 / _324;
    float _326 = _287 * 0.5f;
    float _327 = _326 + 0.5f;
    float _328 = _327 * _327;
    float _329 = 1.0f - _328;
    float _330 = _297 * _329;
    float _331 = _330 + _328;
    float _332 = _303 * _331;
    float _333 = _303 * _329;
    float _334 = _333 + _328;
    float _335 = _334 * _297;
    float _336 = _332 + 9.999999747378752e-06f;
    float _337 = _336 + _335;
    float _338 = 0.5f / _337;
    float _339 = _314 * _325;
    float _340 = _315 * _325;
    float _341 = _316 * _325;
    float _342 = _339 * _338;
    float _343 = _340 * _338;
    float _344 = _341 * _338;
    float _345 = -0.0f - _279;
    float _346 = -0.0f - _280;
    float _347 = -0.0f - _281;
    float _348 = dot(float3(_345, _346, _347), float3(LIGHTDIR.x, LIGHTDIR.y, LIGHTDIR.z));
    if (!_11) {
      float _350 = abs(_348);
      _352 = _350;
    } else {
      _352 = _348;
    }
    float _353 = _352 - CONE;
    float _354 = 1.0f - CONE;
    float _355 = _353 / _354;
    float _356 = saturate(_355);
    int _359 = asint((CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[6].w));
    bool _360 = (_359 == 2);
    if (_360) {
      float _365 = _28 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].z);
      float _366 = _29 - (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[294].w);
      _368 = _365;
      _369 = _366;
    } else {
      _368 = _28;
      _369 = _29;
    }
    float4 _372 = t4.SampleLevel(s1, float2(_368, _369), 0.0f);
    uint _374 = 1 << _51;
    int _375 = _374 & 104;
    bool _376 = (_375 == 0);
    if (!_376) {
      float _378 = _372.x + 0.25f;
      float _379 = saturate(_378);
      _381 = _379;
    } else {
      _381 = _372.x;
    }
    float _382 = _66 * 0.31830987334251404f;
    float _383 = _67 * 0.31830987334251404f;
    float _384 = _68 * 0.31830987334251404f;
    float _385 = _342 + _382;
    float _386 = _343 + _383;
    float _387 = _344 + _384;
    float _388 = _283 * INTENSITY.x;
    float _389 = _388 * _286;
    float _390 = _389 * _303;
    float _391 = _390 * _385;
    float _392 = _391 * _356;
    float _393 = _392 * _381;
    float _394 = _283 * INTENSITY.y;
    float _395 = _394 * _286;
    float _396 = _395 * _303;
    float _397 = _396 * _386;
    float _398 = _397 * _356;
    float _399 = _398 * _381;
    float _400 = _283 * INTENSITY.z;
    float _401 = _400 * _286;
    float _402 = _401 * _303;
    float _403 = _402 * _387;
    float _404 = _403 * _356;
    float _405 = _404 * _381;
    int _406 = _44.x & 8388608;
    bool _407 = (_406 == 0);
    if (_407) {
      float _409 = _72 + -0.5f;
      float _410 = _409 * 2.0f;
      float _411 = saturate(_410);
      float _412 = _411 * 2.0f;
      float _413 = 3.0f - _412;
      float _414 = _411 * _411;
      float _415 = _414 * _413;
      float _416 = _415 * _393;
      float _417 = _415 * _399;
      float _418 = _415 * _405;
      _420 = _416;
      _421 = _417;
      _422 = _418;
    } else {
      _420 = _393;
      _421 = _399;
      _422 = _405;
    }
  } else {
    _420 = 0.0f;
    _421 = 0.0f;
    _422 = 0.0f;
  }
  float _425 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL) * _420;
  float _426 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL) * _421;
  float _427 = (CBufferGlobalConstant_Z_000.StructGlobalConstant_Z_000[86].x * MSFS2024_LIGHT_SPILL) * _422;
  SV_Target.x = _425;
  SV_Target.y = _426;
  SV_Target.z = _427;
  return SV_Target;
}
