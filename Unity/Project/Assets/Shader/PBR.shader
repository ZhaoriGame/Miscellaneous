Shader "Custom/PBR"
{
    Properties
    {
        [MainTexture]_BaseMap("Albedo",2D) = "white"{}
        [MainColor]_BaseColor("Color",Color) = (1,1,1,1)
    }
    SubShader
    {
       Tags{"RenderType" = "Opaque" "RenderPipiline" = "UniversalPipeline"}
       
       Pass
       {
           Name "PBR"
           Tags{"LightMode" = "UniversalForward"}
           
           //Blend One One
           HLSLPROGRAM
            #include "PBR.hlsl"
            #pragma vertex PBRVertex
            #pragma fragment PBRFragment
           
           ENDHLSL
       }
       
    }
    FallBack "Diffuse"
}
