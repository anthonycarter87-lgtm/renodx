// FS25 cloud coverage map. RenoDX: Cloud Coverage scales how much of the sky the clouds fill.
#include "./shared.h"

Texture2D<float4> cloudCoverageNoise : register(t0);

Texture2D<float4> localCloudCoverageMap : register(t1);

RWTexture2D<float> outMip1 : register(u0);

cbuffer CloudCoverageParamsCB : register(b0) {
  float2 g_cloudUVOffset : packoffset(c000.x);
  float g_cloudCoverageEdge0 : packoffset(c000.z);
  float g_cloudCoverageEdge1 : packoffset(c000.w);
  float g_cloudCoverageDistanceToCenterStart : packoffset(c001.x);
  float g_cloudCoverageDistanceToCenterEnd : packoffset(c001.y);
  float g_cloudCoverageNoiseWeight0 : packoffset(c001.z);
  float g_cloudCoverageNoise0Edge0 : packoffset(c001.w);
  float g_cloudCoverageNoise0Edge1 : packoffset(c002.x);
  float g_cloudCoverageNoiseWeight1 : packoffset(c002.y);
  float g_cloudCoverageNoise1Edge0 : packoffset(c002.z);
  float g_cloudCoverageNoise1Edge1 : packoffset(c002.w);
  float g_cloudCoverageNoiseWeight2 : packoffset(c003.x);
  float g_cloudCoverageNoise2Edge0 : packoffset(c003.y);
  float g_cloudCoverageNoise2Edge1 : packoffset(c003.z);
  float g_localCloudCoverageWeight0 : packoffset(c003.w);
  float g_localCloudCoverageWeight1 : packoffset(c004.x);
  float g_localCloudCoverageWeight2 : packoffset(c004.y);
  float g_localCloudCoverageWeight3 : packoffset(c004.z);
};

SamplerState samplerBilinearWrap : register(s0);

[numthreads(8, 8, 1)]
void main(
  uint3 SV_DispatchThreadID : SV_DispatchThreadID,
  uint3 SV_GroupID : SV_GroupID,
  uint3 SV_GroupThreadID : SV_GroupThreadID,
  uint SV_GroupIndex : SV_GroupIndex
) {
  float _8 = float((uint)SV_DispatchThreadID.x);
  float _9 = float((uint)SV_DispatchThreadID.y);
  float _10 = _8 + 0.5f;
  float _11 = _9 + 0.5f;
  float _12 = _10 * 0.0009765625f;
  float _13 = _11 * 0.0009765625f;
  float _14 = _10 * 0.001953125f;
  float _15 = _11 * 0.001953125f;
  float _16 = _14 + -1.0f;
  float _20 = _16 + g_cloudUVOffset.x;
  float _21 = g_cloudUVOffset.y + -1.0f;
  float _22 = _21 + _15;
  float _23 = _20 * 0.5f;
  float _24 = _22 * 0.5f;
  float _25 = _23 + 0.5f;
  float _26 = _24 + 0.5f;
  float4 _27 = cloudCoverageNoise.SampleLevel(samplerBilinearWrap, float2(_25, _26), 0.0f);
  float4 _31 = localCloudCoverageMap.SampleLevel(samplerBilinearWrap, float2(_12, _13), 0.0f);
  float _36 = _15 + -1.0f;
  float _37 = _16 * _16;
  float _38 = _36 * _36;
  float _39 = _38 + _37;
  float _40 = sqrt(_39);
  float _47 = dot(float4(_31.x, _31.y, _31.z, _31.w), float4(g_localCloudCoverageWeight0, g_localCloudCoverageWeight1, g_localCloudCoverageWeight2, g_localCloudCoverageWeight3));
  float _54 = _27.x - g_cloudCoverageNoise0Edge0;
  float _55 = g_cloudCoverageNoise0Edge1 - g_cloudCoverageNoise0Edge0;
  float _56 = _54 / _55;
  float _57 = max(_56, 0.0f);
  float _58 = min(_57, 1.0f);
  float _60 = g_cloudCoverageNoiseWeight0 * _58;
  float _63 = _27.y - g_cloudCoverageNoise1Edge0;
  float _64 = g_cloudCoverageNoise1Edge1 - g_cloudCoverageNoise1Edge0;
  float _65 = _63 / _64;
  float _66 = max(_65, 0.0f);
  float _67 = min(_66, 1.0f);
  float _69 = g_cloudCoverageNoiseWeight1 * _67;
  float _70 = _69 + _60;
  float _73 = _27.z - g_cloudCoverageNoise2Edge0;
  float _74 = g_cloudCoverageNoise2Edge1 - g_cloudCoverageNoise2Edge0;
  float _75 = _73 / _74;
  float _76 = max(_75, 0.0f);
  float _77 = min(_76, 1.0f);
  float _79 = g_cloudCoverageNoiseWeight2 * _77;
  float _80 = _70 + _79;
  float _81 = max(_80, 0.0f);
  float _82 = min(_81, 1.0f);
  float _83 = g_cloudCoverageEdge1 - g_cloudCoverageEdge0;
  float _84 = _82 - g_cloudCoverageEdge0;
  float _85 = _84 / _83;
  float _86 = saturate(_85);
  float _87 = _86 * 2.0f;
  float _88 = 3.0f - _87;
  float _91 = g_cloudCoverageDistanceToCenterEnd - g_cloudCoverageDistanceToCenterStart;
  float _92 = _40 - g_cloudCoverageDistanceToCenterStart;
  float _93 = _92 / _91;
  float _94 = saturate(_93);
  float _95 = _94 * 2.0f;
  float _96 = 3.0f - _95;
  float _97 = 1.0f - _47;
  float _98 = _86 * _94;
  float _99 = _98 * _98;
  float _100 = _88 * _97;
  float _101 = _100 * _96;
  float _102 = _101 * _99;
  float _103 = _102 + _47;
  float _104 = max(_103, 0.0f);
  float _105 = min(_104, 1.0f);
  outMip1[int2((uint)(SV_DispatchThreadID.x), (uint)(SV_DispatchThreadID.y))] = saturate(_105 * CUSTOM_CLOUD_COVERAGE);
}
