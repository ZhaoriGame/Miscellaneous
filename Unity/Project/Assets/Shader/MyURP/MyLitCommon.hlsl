#ifndef MY_LIT_COMMON_INCLUDED
#define MY_LIT_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetalnessMask); SAMPLER(sampler_MetalnessMask);
TEXTURE2D(_SpecularMap); SAMPLER(sampler_SpecularMap);
TEXTURE2D(_SmoothnessMask); SAMPLER(sampler_SmoothnessMask);
TEXTURE2D(_EmissionMap); SAMPLER(sampler_EmissionMap);
TEXTURE2D(_ParallaxMap); SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_ClearCoatMask); SAMPLER(sampler_ClearCoatMask);
TEXTURE2D(_ClearCoatSmoothnessMask); SAMPLER(sampler_ClearCoatSmoothnessMask);

//CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _BaseColor;
float _Cutoff;
float _NormalStrength;
float _Metalness;
float3 _SpecularTint;
float _Smoothness;
float3 _EmissionTint;
float _ParallaxStrength;
float _ClearCoatStrength;
float _ClearCoatSmoothness;
//CBUFFER_END

void TestAlphaClip(float4 colorSample) {
    #ifdef _ALPHA_CUTOUT
    clip(colorSample.a * _BaseColor.a - _Cutoff);
    #endif
}

#endif
