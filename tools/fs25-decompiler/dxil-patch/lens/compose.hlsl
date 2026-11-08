// Stage B: compose lens drops on FS25 vehicle glass (premultiplied blend: rgb is added light, alpha hides background)
// X0 = wetness, strength, time | X1 = droplet normal-map xy, projected uv | X2 = glass rgb, alpha | X3 = sky rgb
float Hash11(float p) { p = frac(p * 0.1031f); p *= p + 33.33f; p *= p + p; return frac(p); }
void main(float3 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float3 X3 : TEXCOORD3,
          out float4 O0 : SV_Target0) {
  float wet = saturate(X0.x) * X0.y;
  float time = X0.z;
  // static drops from the game's droplet normal map: tilt 0 = flat (centre or no drop), high = steep rim
  float2 dn = (X1.xy - 0.5f) * 2.0f;
  float tilt = saturate(length(dn) * 2.2f);
  // running drops: random 7 cm columns on the projected uv (v = local up on vertical glass), head + trail sliding down
  float h = X1.z * 14.0f;
  float col = floor(h);
  float r0 = Hash11(col * 1.37f + 0.11f);
  float r1 = Hash11(col * 2.71f + 3.7f);
  float r2 = Hash11(col * 5.13f + 9.2f);
  float active = step(0.65f, r0);
  float speed = 0.08f + 0.20f * r1;                     // m/s
  float yy = X1.w * 3.0f + time * speed * 3.0f + r2 * 7.0f;
  float cell = frac(yy);
  float dx = abs(frac(h) - 0.5f - 0.10f * sin(yy * 6.2831f + r1 * 6.2831f));
  float headD = length(float2(dx / 0.22f, (cell - 0.09f) / 0.07f));      // 0 at head centre, 1 at its edge
  float head = saturate(1.0f - headD);
  float trail = smoothstep(0.06f, 0.02f, dx) * smoothstep(0.14f, 0.22f, cell) * smoothstep(0.8f, 0.3f, cell);
  float headIn = step(0.0001f, head);
  float runTilt = max(sqrt(saturate(1.0f - head * head)) * headIn, trail * 0.6f);   // dome: steep at edges
  float runMask = active * max(headIn, trail);
  tilt = max(tilt, runTilt * runMask);
  float body = smoothstep(0.08f, 0.45f, tilt) * wet;    // bent-light part of the drop
  float rim = smoothstep(0.7f, 1.0f, tilt) * wet;       // steep edge: total internal reflection -> dark
  float3 rgb = X2.rgb + X3 * 0.6f * body * (1.0f - rim);
  float a = lerp(X2.a, 0.55f, body);
  a = lerp(a, 0.85f, rim);
  O0 = float4(rgb, saturate(a));
}
