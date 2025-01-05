//如何在URP中写一个全屏shader？
//（https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@15.0/manual/renderer-features/how-to-fullscreen-blit.html）
//HLSL的shader中的纹理采样器。Unity - Manual: Texture samplers
//（https://docs.unity3d.com/Manual/SL-SamplerStates.html）

Shader "Outline"
{
    Properties
    {
        [HDR] _OutlineColor ("Outline Color",Color) = (1,1,1,1)
        _OutlineWidth("Outline Width", Range(0, 0.005)) = 0.002
        
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        
        
        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include  "Packages/com.unity.render-pipelines.core//ShaderLibrary//Common.hlsl"

            #pragma  vertex vert
            #pragma  fragment  frag

            struct  Attributes
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                half2 offsets[8] : TEXCOORD1;
            };

            TEXTURE2D_X(_OutlineMask);
            SAMPLER(sampler_linear_clamp_OutlineMask);

            half4 _OutlineColor;
            half _OutlineWidth;

            Varyings vert(Attributes IN)
            {
                Varyings output;
                output.positionCS = GetFullScreenTriangleVertexPosition(IN.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(IN.vertexID);

                //屏幕修正
                const half aspectRatio = _ScreenParams.x/_ScreenParams.y;
                //对角修正
                const half diagonalCorrection = 0.707;

                output.offsets[0] = half2(-1,aspectRatio) * _OutlineWidth * diagonalCorrection;
                output.offsets[1] = half2(0,aspectRatio) * _OutlineWidth;
                output.offsets[2] = half2(1,aspectRatio) * _OutlineWidth *diagonalCorrection;
                output.offsets[3] = half2(-1,0) * _OutlineWidth;

                output.offsets[4] = half2(1,0) * _OutlineWidth;
                output.offsets[5] = half2(-1,-aspectRatio) * _OutlineWidth * diagonalCorrection;
                output.offsets[6] = half2(0,-aspectRatio) * _OutlineWidth;
                output.offsets[7] = half2(1,-aspectRatio) * _OutlineWidth * diagonalCorrection;
                return output;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                const half kernelX[8] =
                {
                    -1,0,1,
                    -2,  2,
                    -1,0,1
                };

                const half kernelY[8] =
                {
                    -1,-2,-1,
                    0,     0,
                    1,  2, 1
                };

                half gx = 0;
                half gy = 0;

                half mask;
                for (int i = 0; i<8; i++)
                {
                    mask = SAMPLE_TEXTURE2D_X(_OutlineMask,sampler_linear_clamp_OutlineMask,IN.uv + IN.offsets[i]).a;
                    gx += mask * kernelX[i];
                    gy += mask * kernelY[i];
                }

                const half alpha = SAMPLE_TEXTURE2D_X(_OutlineMask,sampler_linear_clamp_OutlineMask,IN.uv).a;
                
                half4 col = _OutlineColor;
                col.a = saturate(abs(gx)+ abs(gy))* (1-alpha);
                return col;
            }
            

            ENDHLSL
        }
    }
}