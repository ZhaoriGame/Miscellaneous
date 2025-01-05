#ifndef MY_LIT_FORWARD_LIT_PASS_INCLUDED
#define MY_LIT_FORWARD_LIT_PASS_INCLUDED

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "MyLitCommon.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

#define UNITY_VERSION 20223013

struct a2v
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float4 tangentOS : TANGENT;
	float2 uv:TEXCOORD0;
};

struct v2f
{
	float4 positionCS : SV_POSITION;
	float2 uv:TEXCOORD0;
	float3 positionWS : TEXCOORD1;
	float3 normalWS : TEXCOORD2;
	float4 tangentWS : TEXCOORD3;
	// float3 normalVS: TEXCOORD4;
	// float3 positionVS : TEXCOORD5;
	// float4 positionNDC : TEXCOORD6;
};

v2f Vertex (a2v v)
{
	v2f o;
	VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
	VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS);

	o.uv = TRANSFORM_TEX(v.uv,_BaseMap);
	o.positionCS = positionInputs.positionCS;
	o.positionWS = positionInputs.positionWS;
	o.normalWS = normalInputs.normalWS;
	o.tangentWS = float4(normalInputs.tangentWS,v.tangentOS.w);
	// o.normalVS =  TransformWorldToViewDir(v.normalOS,true);
	// o.positionVS = positionInputs.positionVS;
	// o.positionNDC = positionInputs.positionNDC;

    		
	return o;
}
           

float4 Fragment(v2f input
	//双面渲染时需要确定法线方向
#ifdef _DOUBLE_SIDED_NORMALS
, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC
#endif
	): SV_Target
{
	float3 normalWS = normalize(input.normalWS);

	#ifdef _DOUBLE_SIDED_NORMALS
	normalWS *= IS_FRONT_VFACE(frontFace, 1, -1);
	#endif

	float3 positionWS = input.positionWS;
	float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
	float3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, normalWS, viewDirWS);
		
	float2 uv = input.uv;
	uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _ParallaxStrength, uv);
	
	float4 colorSample   = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv) * _BaseColor;
	TestAlphaClip(colorSample);

#ifdef _NORMALMAP	
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalStrength);
	float3x3 tangentToWorld = CreateTangentToWorld(normalWS,input.tangentWS.xyz,input.tangentWS.w);
	normalWS = normalize(TransformTangentToWorld(normalTS,tangentToWorld));
#else
	float3 normalTS = float3(0,0,1);
	normalWS = normalize(normalWS);
#endif
	
	InputData lightingInput = (InputData)0;
	lightingInput.positionWS = normalize(positionWS);
	lightingInput.normalWS = normalWS;
	lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(positionWS);
	lightingInput.shadowCoord = TransformWorldToShadowCoord(positionWS);
#if UNITY_VERSION >= 202120
	lightingInput.positionCS = input.positionCS;
#ifdef _NORMALMAP	
	lightingInput.tangentToWorld = tangentToWorld;
#endif
#endif
           	
	SurfaceData  surfaceInput = (SurfaceData)0;
	surfaceInput.albedo = colorSample.rgb ;
	surfaceInput.alpha = colorSample.a;

#ifdef _SPECULAR_SETUP
	surfaceInput.specular = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv).rgb * _SpecularTint;
	surfaceInput.metallic = 0;
#else
	surfaceInput.specular = 1;
	surfaceInput.metallic = SAMPLE_TEXTURE2D(_MetalnessMask, sampler_MetalnessMask, uv).r * _Metalness;
#endif
	
	surfaceInput.smoothness = SAMPLE_TEXTURE2D(_SmoothnessMask, sampler_SmoothnessMask, uv).r * _Smoothness;
	surfaceInput.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).rgb * _EmissionTint;
	surfaceInput.clearCoatMask = SAMPLE_TEXTURE2D(_ClearCoatMask, sampler_ClearCoatMask, uv).r * _ClearCoatStrength;
	surfaceInput.clearCoatSmoothness = SAMPLE_TEXTURE2D(_ClearCoatSmoothnessMask, sampler_ClearCoatSmoothnessMask, uv).r * _ClearCoatSmoothness;
	surfaceInput.normalTS = normalTS;

	return UniversalFragmentPBR(lightingInput, surfaceInput);
                
}

#endif
