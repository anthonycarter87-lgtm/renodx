// Puddle block spliced into FS25 terrain shader 0x1EB3A314 (see splice.py).
// X0 = world pos xyz, wetness | X1 = normal xyz, roughness | X2 = albedo xyz, puddle amount (0..1)
float Hash12(float2 p) {
  float3 p3 = frac(float3(p.xyx) * 0.1031f);
  p3 += dot(p3, p3.yzx + 33.33f);
  return frac((p3.x + p3.y) * p3.z);
}
float ValueNoise(float2 p) {
  float2 i = floor(p);
  float2 f = frac(p);
  float2 u = f * f * (3.0f - 2.0f * f);
  float a = Hash12(i);
  float b = Hash12(i + float2(1, 0));
  float c = Hash12(i + float2(0, 1));
  float d = Hash12(i + float2(1, 1));
  return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}
void main(float4 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float3 X3 : TEXCOORD3,
          float3 X4 : TEXCOORD4, float3 X5 : TEXCOORD5, float4 X6 : TEXCOORD6, float3 X7 : TEXCOORD7,
          out float4 O0 : SV_Target0, out float4 O1 : SV_Target1) {
  // X3 = cWetness, terrain uv (game TEXCOORD3.xy, absolute & seamless across terrain patches)
  // X4/X5 = ddx/ddy of camera-relative position, X6 = ddx(uv).xy, ddy(uv).xy - all taken in uniform control flow
  float duv = sqrt(dot(X6, X6));
  float dw = sqrt(X4.x * X4.x + X4.z * X4.z + X5.x * X5.x + X5.z * X5.z);
  float metresPerUv = exp2(round(log2(max(dw, 1e-9f) / max(duv, 1e-12f))));
  float2 xz = X3.yz * metresPerUv;
  float n = ValueNoise(xz * 0.22f) * 0.6f + ValueNoise(xz * 0.7f + 17.3f) * 0.3f + ValueNoise(xz * 2.1f + 5.1f) * 0.1f;
  // X0.w = local wetness (global cWetness x rain occlusion), X3 = global cWetness.
  // The rain occlusion map switches cascade along hard world-space lines; only trust it for "clearly covered",
  // otherwise use the global wetness so puddles don't show cascade seams.
  float wet = saturate(X0.w);   // the game's own wetness (cWetness x rain occlusion), as in build 30
  float amount = X2.w;
  float cover = wet * amount;
  float gate = saturate(cover * 4.0f);
  // Slope from the actual surface geometry (world-position derivatives), not the shading normal - that one comes from
  // the baked virtual-texture tiles (detail normals) and made puddles follow texture seams.
  // build 30 flatness gate: puddles only on flattish ground (shading normal y 0.88 -> 0.96 fade)
  float flatness = saturate((X1.y - 0.88f) * 12.5f);
  float th = 0.70f - 0.34f * cover;
  float mask = smoothstep(th, th + 0.03f, n) * gate * flatness;
  float edge = smoothstep(th - 0.12f, th, n) * gate * flatness;
  float3 N = normalize(lerp(X1.xyz, float3(0, 1, 0), mask * 0.8f));   // keep a little ground relief
  // X7 = camera-relative vector. Far terrain is coarse LOD geometry: mirror puddles there show SSR hit/miss shards,
  // so puddle smoothness softens from ~15 m to ~75 m.
  float dist = sqrt(dot(X7, X7));
  float puddleRough = lerp(0.10f, 0.20f, saturate((dist - 15.0f) / 60.0f));   // never a perfect mirror (SSR breaks up)
  float R = lerp(X1.w, puddleRough, mask);
  float3 A = X2.xyz * lerp(1.0f, 0.6f, edge) * lerp(1.0f, 0.4f, mask);
  O0 = float4(N, R);
  O1 = float4(A, 0);
}
