#ifndef SRC_GAMES_MSFS2024_DEBUG_HLSLI_
#define SRC_GAMES_MSFS2024_DEBUG_HLSLI_

// Build 1 debug aid: magenta veil over the frame plus the shader's variant
// number drawn as 5 binary bars (white = 1, dark = 0, MSB on the left) in
// the top-left corner, so a screenshot tells us which variant ran.
float3 DebugTint(float3 color, float2 position, uint variant_id) {
  float3 tinted = lerp(color, float3(1.f, 0.f, 1.f), 0.2f);

  const float BAR_SIZE = 64.f;
  const float BAR_GAP = 16.f;
  const uint BIT_COUNT = 5u;
  float2 origin = position - 32.f;
  if (origin.x < 0.f || origin.y < 0.f || origin.y >= BAR_SIZE) return tinted;

  uint slot = uint(origin.x / (BAR_SIZE + BAR_GAP));
  if (slot >= BIT_COUNT) return tinted;
  if (origin.x - float(slot) * (BAR_SIZE + BAR_GAP) >= BAR_SIZE) return float3(0.f, 0.f, 0.f);

  uint bit = (variant_id >> (BIT_COUNT - 1u - slot)) & 1u;
  return (bit != 0u) ? float3(1.f, 1.f, 1.f) : float3(0.05f, 0.05f, 0.05f);
}

#endif  // SRC_GAMES_MSFS2024_DEBUG_HLSLI_
