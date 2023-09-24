#ifndef UNIVERSAl_PBR
#define UNIVERSAL_PBR
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// ReSharper disable CppLocalVariableMayBeConst

sampler2D _BaseMap;

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
CBUFFER_END

struct Attributes
{
   float4 positionOS : POSITION;
   float2 texcoord   : TEXCOORD0;
};

struct Varyings
{
   float4 positionCS : SV_POSITION;
   float2 uv : TEXCOORD0;
};


Varyings PBRVertex(Attributes input)
{
   Varyings output = (Varyings)0;


   VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
   output.positionCS = vertexInput.positionCS;
   output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap); 
   
   return output;
}

half4 PBRFragment(Varyings input) : SV_Target
{
   //input.uv
   //return half4(1,1,1,1);
   
   return half4(input.uv.xy,1,1);
}

//Lambert (兰伯特) 光照模型
//Diffuse = 直射光颜色 *材质颜色 * max(0,cos夹角(光和法线的夹角))

half3 PBRLightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
   half NdotL = saturate(dot(normal, lightDir));
   return lightColor * NdotL;
}

half3 PBRCalculateBlinnPhong(Light light, float3 normalWS, half3 albedo)
{
   half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
   half3 lightColor = PBRLightingLambert(attenuatedLightColor, light.direction, normalWS);
   lightColor *= albedo;
   return lightColor;
}

#endif

