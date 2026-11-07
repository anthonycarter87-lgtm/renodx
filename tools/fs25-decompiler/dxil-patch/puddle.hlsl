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
void main(float4 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2,
          out float4 O0 : SV_Target0, out float4 O1 : SV_Target1) {
  float2 xz = X0.xz;
  float n = ValueNoise(xz * 0.22f) * 0.6f + ValueNoise(xz * 0.7f + 17.3f) * 0.3f + ValueNoise(xz * 2.1f + 5.1f) * 0.1f;
  float wet = saturate(X0.w);
  float amount = X2.w;
  float cover = wet * amount;
  float gate = saturate(cover * 4.0f);
  float flatness = saturate((X1.y - 0.88f) * 12.5f);
  float th = 0.70f - 0.34f * cover;
  float mask = smoothstep(th, th + 0.03f, n) * gate * flatness;
  float edge = smoothstep(th - 0.12f, th, n) * gate * flatness;
  float3 N = normalize(lerp(X1.xyz, float3(0, 1, 0), mask));
  float R = lerp(X1.w, 0.02f, mask);
  float3 A = X2.xyz * lerp(1.0f, 0.6f, edge) * lerp(1.0f, 0.4f, mask);
  O0 = float4(N, R);
  O1 = float4(A, 0);
}
