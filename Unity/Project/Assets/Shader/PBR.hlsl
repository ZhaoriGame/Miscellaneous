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

half Distribution(float roughness, float nh)
{
   float lerpSquareRoughness = pow(lerp(0.002,1,roughness),2);
   float d = lerpSquareRoughness/(pow((pow(nh,2)*(lerpSquareRoughness-1)+1),2)* PI);
   return d;
}

half Geometry(float roughness, float nl , float nv)
{
   //直接光照
   float kInDirectLight = pow(roughness+ 1,2)/ 8;
   //间接光照(IBL)
   float kInIBL = pow(roughness,2) / 8;
   float GLeft = nl / lerp(nl,1,kInDirectLight);
   float GRight = nv/lerp(nv,1,kInDirectLight);
   float G = GLeft*GRight;
   return G;
}

half3 FresnelEquation(float3 F0, float vh)
{
   half3 F = F0 + (1-F0) * exp2((-5.55473 * vh - 6.98316)* vh);
   return F;
}

// half4 FragmentPBR(half3 normalWS,half3 viewDirWS,half3 lightDirWS)
// {
//    //D
//    half4 color;
//    half3 halfDir = normalize(viewDirWS + lightDirWS);
//    //float ggXValue =  D_GGX(normalWS,halfDir,_Roughness);
//   
//    return half4(ggXValue,ggXValue,ggXValue,1);  
// }

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
   float LDotH = max(saturate(dot(lightDirWS,halfDirWS)),0.00001);
   float NDotH = max(saturate(dot(normalWS,halfDirWS)),0.00001);

   
   half D =  Distribution(roughness,NDotH);
   half G =  Geometry(roughness,NDotL,NDotV);
   float3 F0 = lerp(float3(0.04,0.04,0.04), Albedo, _Metallic);
   half3 F = FresnelEquation(F0,VDotH);

   
   half3 SpecularResult = (D*G*F) / (NDotV * NDotL *4);
   half3 speColor = SpecularResult * lightColor * NDotL * PI;

   speColor = saturate(speColor);

   half3 kd = (1- F) * (1- _Metallic);
   half3 diffuseColor = kd * Albedo * lightColor * NDotL;

   half3 directionLight = speColor + diffuseColor;


   

   // //***********间接光照-镜面反射部分********* 
   // half mip = CubeMapMip(_Roughness);                              //计算Mip等级，用于采样CubeMap
   // float3 reflectVec = reflect(-viewDir, i.normal);                //计算反射向量，用于采样CubeMap
   //
   // half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip);
   // float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);      //采样CubeMap之后，储存在四维向量rgbm中，然后在使用函数DecodeHDR解码到rgb
   //
   // half surfaceReduction=1.0/(roughness*roughness+1.0);            //压暗非金属的反射
   //
   // float oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a-unity_ColorSpaceDielectricSpec.a*_Metallic;
   // half grazingTerm=saturate((1 - _Roughness)+(1-oneMinusReflectivity));
   // half t = Pow5(1-nv);
   // float3 FresnelLerp =  lerp(F0,grazingTerm,t);                   //控制反射的菲涅尔和金属色
   //
   // float3 iblSpecularResult = surfaceReduction*iblSpecular*FresnelLerp;
   // //***********间接光照-镜面反射部分完成********* 
   //
   // //***********间接光照-漫反射部分********* 
   // half3 iblDiffuse = ShadeSH9(float4(normal,1));                  //获取球谐光照
   //
   // float3 Flast = fresnelSchlickRoughness(max(nv, 0.0), F0, roughness);
   // float kdLast = (1 - Flast) * (1 - _Metallic);                   //压暗边缘，边缘处应当有更多的镜面反射
   //
   // float3 iblDiffuseResult = iblDiffuse * kdLast * Albedo;
   // //***********间接光照-漫反射部分完成********* 
   // float3 indirectResult = iblSpecularResult + iblDiffuseResult;
   // //***********间接光照完成********* 

   
   return half4(directionLight.xyz,1);
}



#endif

