#ifndef UNIVERSAl_PBR
#define UNIVERSAL_PBR
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// ReSharper disable CppLocalVariableMayBeConst


TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;

half _Roughness;
half _Metallic;
CBUFFER_END

struct Attributes
{
   float4 positionOS : POSITION;
   float3 normalOS : NORMAL;
   float4 tangentOS : TANGENT;
   float2 texcoord   : TEXCOORD0;
   UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
   float4 positionCS : SV_POSITION;
   float2 uv : TEXCOORD0;
   float3 positionWS : TEXCOORD1;
   float3 normalWS : TEXCOORD2;
   float4 tangentWS : TEXCOORD3;
   half3 viewDirWS : TEXCOORD4;
   UNITY_VERTEX_INPUT_INSTANCE_ID
   UNITY_VERTEX_OUTPUT_STEREO
};




Varyings PBRVertex(Attributes input)
{
   Varyings output = (Varyings)0;

   
   UNITY_SETUP_INSTANCE_ID(input);
   UNITY_TRANSFER_INSTANCE_ID(input, output);
   UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
   
   output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

   //Position
   VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
   output.positionCS = vertexInput.positionCS;
   output.positionWS = vertexInput.positionWS;

   //Normal
   VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
   output.normalWS = normalInput.normalWS;
   half sign = input.tangentOS.w * GetOddNegativeScale();
   half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
   output.tangentWS = tangentWS;

   half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
   //half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS,output.normalWS, viewDirWS);

    
   
   output.viewDirWS = viewDirWS;
   
   return output;
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

float D_GGX(half3 N,half3 H,float a)
{
   float a2 = a*a;
   float NDotH = max(dot(N,H),0);
   float NDotH2 = NDotH * NDotH;
   float nom= a2;
   float denom = (NDotH2 * (a2 -1)+1);
   denom = PI * denom * denom;
   return nom / denom;
}

half4 FragmentPBR(half3 normalWS,half3 viewDirWS,half3 lightDirWS)
{
   //D
   half4 color;
   half3 halfDir = normalize(viewDirWS + lightDirWS);
   float ggXValue =  D_GGX(normalWS,halfDir,_Roughness);
   
   return half4(ggXValue,ggXValue,ggXValue,1);  
}

//https://zhuanlan.zhihu.com/p/364932774
half4 PBRFragment(Varyings input) : SV_Target
{
   UNITY_SETUP_INSTANCE_ID(input);
   UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
   Light mainLight = GetMainLight();
   half3 normalWS = normalize(input.normalWS);
   half3 viewDirWS = normalize(input.viewDirWS);
   half3 lightDirWS = mainLight.direction;
   half3 lightColor = mainLight.color;

   //半角向量
   half3 halfDirWS = normalize(viewDirWS + lightDirWS);

   float roughness = _Roughness * _Roughness;
   float squareRoughness = roughness * roughness;

   float Albedo = lightColor  * SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
   
   float NDotL = max(saturate(dot(normalWS,lightDirWS)),0.00001);
   float NDotV = max(saturate(dot(normalWS,viewDirWS)),0.00001);
   float VDotH = max(saturate(dot(viewDirWS,halfDirWS)),0.00001);

   
   half4 color = FragmentPBR(normalWS,viewDirWS,lightDirWS);
   
   return color;
}



#endif

