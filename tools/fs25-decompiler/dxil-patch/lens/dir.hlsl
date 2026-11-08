// Stage A: direction to sample the sky cube through a droplet (refraction approximation).
// X0 = world normal xyz | X1 = point->camera xyz | X2 = world tangent xyz, handedness | X3 = droplet normal-map xy
void main(float3 X0 : TEXCOORD0, float3 X1 : TEXCOORD1, float4 X2 : TEXCOORD2, float2 X3 : TEXCOORD3,
          out float4 O0 : SV_Target0) {
  float3 N = normalize(X0);
  float3 T = normalize(X2.xyz);
  float3 B = cross(N, T) * X2.w;
  float2 dn = (X3 - 0.5f) * 2.0f;
  float3 through = -normalize(X1);
  float3 dir = through + (T * dn.x + B * dn.y) * 3.0f + float3(0.0f, 0.25f, 0.0f);
  O0 = float4(dir, 2.5f);   // xyz direction (unnormalised is fine for a cube), w = mip
}
