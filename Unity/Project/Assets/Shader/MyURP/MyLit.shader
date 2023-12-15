Shader "Custom/MyLit"
{
    Properties
    {
    	[Header(Surface options)] 
        // [MainTexture] and [MainColor] allow Material.mainTexture and Material.color to use the correct properties
        [MainTexture]_BaseMap("Albedo",2D) = "white"{}
        [MainColor]_BaseColor("Color",Color) = (1,1,1,1)
        _Cutoff("Alpha cutout threshold",Range(0,1)) = 0.5
        [NoScaleOffset][Normal] _NormalMap("Normal", 2D) = "bump" {}
        _NormalStrength("Normal strength", Range(0, 1)) = 1
        [NoScaleOffset] _MetalnessMask("Metalness mask", 2D) = "white" {}
        _Metalness("Metalness strength", Range(0, 1)) = 0
        [Toggle(_SPECULAR_SETUP)] _SpecularSetupToggle("Use specular workflow", Float) = 0
        [NoScaleOffset] _SpecularMap("Specular map", 2D) = "white" {}
        _SpecularTint("Specular tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _SmoothnessMask("Smoothness mask", 2D) = "white" {}
        _Smoothness("Smoothness multiplier", Range(0, 1)) = 0.5
        [NoScaleOffset] _EmissionMap("Emission map", 2D) = "white" {}
        [HDR] _EmissionTint("Emission tint", Color) = (0, 0, 0, 0)
        [NoScaleOffset] _ParallaxMap("Height/displacement map", 2D) = "white" {}
        _ParallaxStrength("Parallax strength", Range(0, 1)) = 0.005
        [NoScaleOffset] _ClearCoatMask("Clear coat mask", 2D) = "white" {}
        _ClearCoatStrength("Clear coat strength", Range(0, 1)) = 0
        [NoScaleOffset] _ClearCoatSmoothnessMask("Clear coat smoothness mask", 2D) = "white" {}
        _ClearCoatSmoothness("Clear coat smoothness", Range(0, 1)) = 0
        
        [HideInInspector] _Cull("_Cull Mode",Float) = 2 //2 is Back
        [HideInInspector] _SourceBlend("Source blend",Float) = 0
        [HideInInspector] _DestBlend("Destination blend",Float) = 0
        [HideInInspector] _ZWrite("ZWrite blend",Float) = 0
        [HideInInspector] _SurfaceType("Surface type",Float) = 0
        [HideInInspector] _BlendType("Blend type", Float) = 0
        [HideInInspector] _FaceRenderingMode("Face rendering type",Float) = 0
    }
    SubShader
    {
       Tags{ "RenderType" = "Opaque" "RenderPipiline" = "UniversalPipeline"}
       
       Pass
       {
           Name "ForwardLit"
           Tags{"LightMode" = "UniversalForward"}

           Blend[_SourceBlend][_DestBlend]
           ZWrite[_ZWrite]
           Cull[_Cull]
          
           HLSLPROGRAM

           #define UNITY_VERSION 20223013

           #pragma shader_feature_local_fragment _NORMALMAP
           #define _CLEARCOATMAP
           #pragma shader_feature_local _ALPHA_CUTOUT
           #pragma shader_feature_local _DOUBLE_SIDED_NORMALS
           #pragma shader_feature_local_fragment _SPECULAR_SETUP
           #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

           // Shader variant keywords
           // Unity automatically discards unused variants created using "shader_feature" from your final game build,
           // however it keeps all variants created using "multi_compile"
           // For this reason, multi_compile is good for global keywords or keywords that can change at runtime
           // while shader_feature is good for keywords set per material which will not change at runtime

           // Global URP keywords
#if UNITY_VERSION >= 202120
           #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE 
#else
           #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
           #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#endif
           #pragma multi_compile _ _SHADOWS_SOFT
#if UNITY_VERSION >= 202120
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
#endif

           
           #pragma vertex Vertex
           #pragma fragment Fragment

           #include "MyLitForwardLitPass.hlsl"
           
           ENDHLSL
       }
        
        Pass
        {
            // The shadow caster pass, which draws to shadow maps
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            ColorMask 0 //No color output ,only depth
            
            HLSLPROGRAM

            #pragma shader_feature_local _ALPHA_CUTOUT
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS

            
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "MyLitShadowCasterPass.hlsl"
            
            ENDHLSL
        }
       
    }
    CustomEditor "MyLitCustomInspector"
}
