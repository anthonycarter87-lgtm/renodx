// Stage A: (1) sky-cube direction through a droplet, (2) uv for the sliding-droplet layer.
// X0 = world normal xyz | X1 = point->camera xyz | X2 = world tangent xyz, handedness | X3 = droplet nm xy
// X4 = projected uv (u, v = local up on vertical glass), time
float Hash11(float p) { p = frac(p * 0.1031f); p *= p + 33.33f; p *= p + p; return frac(p); }
void main(float3 X0 : TEXCOORD0, float3 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float2 X3 : TEXCOORD3, float3 X4 : TEXCOORD4,
          out float4 O0 : SV_Target0, out float4 O1 : SV_Target1) {
  float3 N = normalize(X0);
  float3 T = normalize(X2.xyz);
  float3 B = cross(N, T) * X2.w;
  float2 dn = (X3 - 0.5f) * 2.0f;
  float3 through = -normalize(X1);
  float3 dir = through + (T * dn.x + B * dn.y) * 3.0f + float3(0.0f, 0.25f, 0.0f);
  O0 = float4(dir, 2.5f);
  // sliding layer: narrow random columns (~5.5 cm); in ~30% of them the game's droplet texture slides down with
  // stick-slip motion and its own speed. Edges of the column fade so cut drops don't show.
  float u = X4.x;
  float v = X4.y;
  float time = X4.z;
  float h = u * 18.0f;
  float col = floor(h);
  float r0 = Hash11(col * 1.37f + 0.11f);
  float r1 = Hash11(col * 2.71f + 3.7f);
  float r2 = Hash11(col * 5.13f + 9.2f);
  float tt = time * (0.6f + 0.8f * r2) + r1 * 50.0f;
  float g = tt + 0.6f * sin(tt * 1.3f + r0 * 6.28f) / 1.3f;                // monotonic, stalls and surges
  float offset = g * (0.015f + 0.05f * r1);                                 // m of slide
  float colMask = step(0.7f, r0) * smoothstep(0.5f, 0.3f, abs(frac(h) - 0.5f));
  O1 = float4(u + 0.37f + r2 * 0.5f, v + offset + r0 * 3.1f, colMask, 0.0f);
}
