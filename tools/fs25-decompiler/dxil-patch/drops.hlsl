// Spliced into FS25 vehicle glass 0x9A8652D9 (see splice_glass.py).
// X0 = world normal xyz, wetness | X1 = point->camera xyz, strength | X2 = local pos xyz, time (s)
// X3 = local normal xyz, alpha | X4 = droplet normal-map sample xy, projected uv | X5 = colour rgb
float Hash11(float p) { p = frac(p * 0.1031f); p *= p + 33.33f; p *= p + p; return frac(p); }
void main(float4 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float4 X3 : TEXCOORD3,
          float4 X4 : TEXCOORD4, float3 X5 : TEXCOORD5, out float4 O0 : SV_Target0) {
  float strength = X1.w;
  float wet = saturate(X0.w) * strength;
  bool front = dot(X0.xyz, X1.xyz) >= 0.0f;            // face seen from its front
  bool outward = dot(X3.xyz, X2.xyz) >= 0.0f;            // face points away from the object's origin (outer pane)
  // static drops: rims of the game's droplet normal map (centres are flat -> clear, like a lens)
  float rim = saturate((abs(X4.x - 0.5f) + abs(X4.y - 0.5f)) * 5.0f);
  // running drops on vertical glass: random columns, each with a head and a thin trail sliding down
  float vertical = saturate((0.75f - abs(X3.y)) * 4.0f);
  float h = X4.z * 14.0f;                                // ~7 cm columns along the projected horizontal axis
  float col = floor(h);
  float r0 = Hash11(col * 1.37f + 0.11f);
  float r1 = Hash11(col * 2.71f + 3.7f);
  float r2 = Hash11(col * 5.13f + 9.2f);
  float active = step(0.72f, r0);
  float speed = 0.04f + 0.10f * r1;                      // m/s
  float yy = X2.y * 3.0f + X2.w * speed * 3.0f + r2 * 7.0f;
  float cell = frac(yy);                                 // 0..1 within a ~33 cm repeat, increasing upwards
  float dx = abs(frac(h) - 0.5f - 0.12f * sin(yy * 6.2831f + r1 * 6.2831f));
  float head = smoothstep(0.24f, 0.10f, dx) * smoothstep(0.0f, 0.04f, cell) * smoothstep(0.16f, 0.08f, cell);
  float trail = smoothstep(0.07f, 0.02f, dx) * smoothstep(0.12f, 0.2f, cell) * smoothstep(0.75f, 0.35f, cell);
  float run = active * vertical * max(head, trail * 0.5f);
  float drops = saturate(max(rim, run)) * wet * (outward ? 1.0f : 0.0f);
  // front faces: drop rims raise alpha (premultiplied blend darkens what is behind, like a lens edge)
  // back faces (only visible because glass is now double-sided): just the drops, no second layer of glass
  float fade = saturate(strength * 4.0f);
  float aFront = lerp(X3.w, 0.7f, drops);
  float aBack = lerp(X3.w, drops * 0.7f, fade);
  float3 rgbBack = X5 * (1.0f - fade);
  float a = front ? aFront : aBack;
  float3 rgb = front ? X5 : rgbBack;
  O0 = float4(rgb, saturate(a));
}
