#ifndef MY_LIT_SHADOW_CASTER_PASS_INCLUDED
#define MY_LIT_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "MyLitCommon.hlsl"
         

struct a2v
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
#ifdef _ALPHA_CUTOUT
	float2 uv : TEXCOORD0;
#endif	
};

struct v2f
{
	float4 positionCS : SV_POSITION;
#ifdef _ALPHA_CUTOUT
	float2 uv : TEXCOORD0;
#endif
};

float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS) {
	float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
	return normalWS * (dot(normalWS, viewDirWS) < 0 ? -1 : 1);
}

//These are set by Unity for the light currently "rendering" this shadow caster pass
float3 _LightDirection;


// This function offsets the clip space position by the depth and normal shadow biases
float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS)
{
	float3 lightDirectionWS = _LightDirection;

#ifdef _DOUBLE_SIDED_NORMALS	
	normalWS = FlipNormalBasedOnViewDir(normalWS, positionWS);
#endif
	
	// From URP's ShadowCasterPass.hlsl
	float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,lightDirectionWS));

	// We have to make sure that the shadow bias didn't push the shadow out of
	// the camera's view area. This is slightly different depending on the graphics API
#if UNITY_REVERSED_Z
	positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
	positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
	return positionCS;
}

v2f Vertex (a2v input)
{
	v2f o;
	VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
	VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

	o.positionCS = GetShadowCasterPositionCS(positionInputs.positionWS,normalInputs.normalWS);

#ifdef _ALPHA_CUTOUT
	o.uv = TRANSFORM_TEX(input.uv, _BaseMap);
#endif
	
	return o;
}
           

float4 Fragment(v2f input): SV_Target
{
#ifdef _ALPHA_CUTOUT
	float2 uv = input.uv;
	float4 colorSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
	TestAlphaClip(colorSample);
#endif
	
	return 0;
                
}
            
           
#endif
