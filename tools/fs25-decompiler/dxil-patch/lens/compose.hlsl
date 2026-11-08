// Stage B: compose lens drops on FS25 vehicle glass (premultiplied blend: rgb is added light, alpha hides background)
// X0 = wetness, strength, time | X1 = droplet normal-map xy, projected uv | X2 = glass rgb, alpha | X3 = sky rgb
// X4 = sliding-layer droplet nm xy, column mask
float Hash11(float p) { p = frac(p * 0.1031f); p *= p + 33.33f; p *= p + p; return frac(p); }
void main(float3 X0 : TEXCOORD0, float4 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float3 X3 : TEXCOORD3, float3 X4 : TEXCOORD4,
          out float4 O0 : SV_Target0) {
  float wet = saturate(X0.x) * X0.y;
  float time = X0.z;
  // static drops from the game's droplet normal map: tilt 0 = flat (centre or no drop), high = steep rim
  float2 dn = (X1.xy - 0.5f) * 2.0f;
  float tilt = saturate(length(dn) * 2.2f);
  // static drops come and go slowly (new drops land, old ones fade): ~3 cm cells, each visible ~80% of a ~25 s cycle
  float2 cellId = floor(X1.zw * 33.0f);
  float ph = frac(Hash11(cellId.x * 7.13f + cellId.y * 3.71f) + time * 0.04f);
  float alive = smoothstep(0.0f, 0.06f, ph) * smoothstep(0.86f, 0.80f, ph);
  tilt *= alive;
  // sliding drops: the game's droplet texture moving down in a few columns
  float2 dn2 = (X4.xy - 0.5f) * 2.0f;
  float tilt2 = saturate(length(dn2) * 2.2f) * X4.z;
  tilt = max(tilt, tilt2);
  float body = smoothstep(0.08f, 0.45f, tilt) * wet;    // bent-light part of the drop
  float rim = smoothstep(0.7f, 1.0f, tilt) * wet;       // steep edge: total internal reflection -> dark
  float3 rgb = X2.rgb + X3 * 0.6f * body * (1.0f - rim);
  float a = lerp(X2.a, 0.55f, body);
  a = lerp(a, 0.85f, rim);
  O0 = float4(rgb, saturate(a));
}
