// Stage A: sky-cube direction through the droplet in front (static or sliding).
// X0 = world normal xyz | X1 = point->camera xyz | X2 = world tangent xyz, handedness
// X3 = static droplet nm xy, sliding droplet nm xy | X4 = sliding column mask
void main(float3 X0 : TEXCOORD0, float3 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float4 X3 : TEXCOORD3, float X4 : TEXCOORD4,
          out float4 O0 : SV_Target0) {
  float3 N = normalize(X0);
  float3 T = normalize(X2.xyz);
  float3 B = cross(N, T) * X2.w;
  float2 dnS = (X3.xy - 0.5f) * 2.0f;
  float2 dnM = (X3.zw - 0.5f) * 2.0f * X4;
  float2 dn = dot(dnM, dnM) > dot(dnS, dnS) ? dnM : dnS;
  float3 through = -normalize(X1);
  float3 dir = through + (T * dn.x + B * dn.y) * 3.0f + float3(0.0f, 0.25f, 0.0f);
  O0 = float4(dir, 2.5f);
}
