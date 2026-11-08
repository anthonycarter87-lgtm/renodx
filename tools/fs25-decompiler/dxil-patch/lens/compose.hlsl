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
  // running drops: two layers of random columns; each column/cycle only sometimes has a drop, with its own speed,
  // lateral offset and stop-start (stick-slip) motion. Heads are lens domes, trails faint and broken.
  float runTilt = 0.0f;
  float runMask = 0.0f;
  [unroll] for (int layer = 0; layer < 2; ++layer) {
    float colsPerM = layer == 0 ? 11.0f : 17.0f;
    float h = X1.z * colsPerM + layer * 0.37f;
    float col = floor(h);
    float r1 = Hash11(col * 2.71f + 3.7f + layer * 19.1f);
    float r2 = Hash11(col * 5.13f + 9.2f + layer * 7.3f);
    float speed = 0.06f + 0.16f * r1;                                         // m/s average
    float tt = time * (1.0f + 0.5f * r2) + r2 * 40.0f;
    float g = tt + 0.55f * sin(tt * 1.9f + r1 * 6.28f) / 1.9f;               // monotonic, surges and stalls
    float yy = X1.w * 2.0f + g * speed * 2.0f + r2 * 13.0f;                    // ~50 cm cycles
    float cyc = floor(yy);
    float cell = frac(yy);
    float rc = Hash11(cyc * 3.17f + col * 11.3f + layer * 5.1f);
    float present = step(0.78f, rc);                                          // ~22% of column-cycles
    float lane = 0.25f + 0.5f * Hash11(cyc * 7.9f + col);                     // lateral position in the column
    float dx = abs(frac(h) - lane - 0.06f * sin(yy * 9.0f + rc * 6.28f));
    float size = 0.55f + 0.45f * rc;
    float headD = length(float2(dx / (0.16f * size), (cell - 0.08f) / (0.05f * size)));
    float head = step(headD, 1.0f);
    float trailOn = step(0.5f, frac(cell * 7.0f + rc * 3.0f));               // broken trail
    float trail = smoothstep(0.035f, 0.01f, dx) * smoothstep(0.12f, 0.18f, cell) * smoothstep(0.6f, 0.2f, cell) * trailOn;
    float t = max(head * headD * 0.95f, trail * 0.25f);                      // dome: 0 centre -> steep edge
    runTilt = max(runTilt, t * present);
    runMask = max(runMask, max(head, trail) * present);
  }
  tilt = max(tilt, runTilt * runMask);
  float body = smoothstep(0.08f, 0.45f, tilt) * wet;    // bent-light part of the drop
  float rim = smoothstep(0.7f, 1.0f, tilt) * wet;       // steep edge: total internal reflection -> dark
  float3 rgb = X2.rgb + X3 * 0.6f * body * (1.0f - rim);
  float a = lerp(X2.a, 0.55f, body);
  a = lerp(a, 0.85f, rim);
  O0 = float4(rgb, saturate(a));
}
