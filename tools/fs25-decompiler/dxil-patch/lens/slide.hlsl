// Stage S: uv for the sliding-droplet layer. X0 = projected u, v, time
float Hash11(float p) { p = frac(p * 0.1031f); p *= p + 33.33f; p *= p + p; return frac(p); }
void main(float3 X0 : TEXCOORD0, out float4 O0 : SV_Target0) {
  float u = X0.x;
  float v = X0.y;
  float time = X0.z;
  float h = u * 18.0f;
  float col = floor(h);
  float r0 = Hash11(col * 1.37f + 0.11f);
  float r1 = Hash11(col * 2.71f + 3.7f);
  float r2 = Hash11(col * 5.13f + 9.2f);
  float tt = time * (0.6f + 0.8f * r2) + r1 * 50.0f;
  float g = tt + 0.6f * sin(tt * 1.3f + r0 * 6.28f) / 1.3f;
  float offset = g * (0.015f + 0.05f * r1);
  float colMask = step(0.7f, r0) * smoothstep(0.5f, 0.3f, abs(frac(h) - 0.5f));
  O0 = float4(u + 0.37f + r2 * 0.5f, v + offset + r0 * 3.1f, colMask, 0.0f);
}
