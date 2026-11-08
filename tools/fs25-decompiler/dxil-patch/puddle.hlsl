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
void main(float4 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float X3 : TEXCOORD3,
          out float4 O0 : SV_Target0, out float4 O1 : SV_Target1) {
  float2 xz = X0.xz;
  float n = ValueNoise(xz * 0.22f) * 0.6f + ValueNoise(xz * 0.7f + 17.3f) * 0.3f + ValueNoise(xz * 2.1f + 5.1f) * 0.1f;
  // X0.w = local wetness (global cWetness x rain occlusion), X3 = global cWetness.
  // The rain occlusion map switches cascade along hard world-space lines; only trust it for "clearly covered",
  // otherwise use the global wetness so puddles don't show cascade seams.
  float exposed = smoothstep(0.05f, 0.5f, saturate(X0.w / max(X3, 0.001f)));
  float wet = saturate(X3) * exposed;
  float amount = X2.w;
  float cover = wet * amount;
  float gate = saturate(cover * 4.0f);
  float slope = saturate((0.97f - X1.y) * 8.0f);
  float th = 0.70f - 0.34f * cover + slope * 0.4f;
  float mask = smoothstep(th, th + 0.05f, n) * gate;
  float edge = smoothstep(th - 0.12f, th, n) * gate;
  float3 N = normalize(lerp(X1.xyz, float3(0, 1, 0), mask));
  float R = lerp(X1.w, 0.02f, mask);
  float3 A = X2.xyz * lerp(1.0f, 0.6f, edge) * lerp(1.0f, 0.4f, mask);
  O0 = float4(N, R);
  O1 = float4(A, 0);
}
