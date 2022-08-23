Shader "QNPR/Outline"
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white" {}
        [Toggle]_ENABLE_ALPHA_TEST("Enable AlphaTest",float) = 0
        _Cutoff("Cutoff", Range(0,1)) = 0.5
        _OutlineWidth("OutlineWidth", Range(0, 10)) = 0.4
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        [Toggle]_OLWVWD("OutlineWidth Varies With Distance?", float) = 0
    }
        SubShader
        {
            HLSLINCLUDE
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"         
                #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
                #pragma shader_feature _ENABLE_ALPHA_TEST_ON
                #pragma shader_feature _OLWVWD_ON
                CBUFFER_START(UnityPerMaterial)
                    float _Cutoff;
                    float _OutlineWidth;
                    float4 _OutlineColor;
                CBUFFER_END
                TEXTURE2D(_BaseMap);                 SAMPLER(sampler_BaseMap);
                struct Attributes {
                    float4 positionOS : POSITION;
                    float4 normalOS : NORMAL;
                    float4 texcoord : TEXCOORD;
                };
                struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD1;
                };
            ENDHLSL
            Pass
            {
                Tags{"LightMode" = "UniversalForward"}
                Cull off
                HLSLPROGRAM
            #pragma target 3.0
                #pragma vertex Vertex
                #pragma fragment Frag
                Varyings Vertex(Attributes input)
                {
                    Varyings output;
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                    output.positionCS = vertexInput.positionCS;
                    output.uv = input.texcoord.xy;
                    return output;
                }
                float4 Frag(Varyings input) :SV_Target
                {
                    float4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv);
                    #if _ENABLE_ALPHA_TEST_ON
                        clip(BaseMap.a - _Cutoff);
                    #endif
                    return BaseMap;
                }
                ENDHLSL
            }
            Pass {
                Name "OutLine"
                Tags{ "LightMode" = "SRPDefaultUnlit" }
            Cull front
            HLSLPROGRAM
            #pragma vertex vert  
            #pragma fragment frag
            Varyings vert(Attributes input) {
                    float4 scaledScreenParams = GetScaledScreenParams();
                    float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);
            Varyings output;

                    float4 clipPosition = TransformObjectToHClip(input.positionOS.xyz);
            //
                    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
                    float3 normalCS = TransformWorldToHClipDir(normalInput.normalWS);
                    float2 extendDis = normalize(normalCS.xy) * (_OutlineWidth * 0.01);
                    extendDis.x /= ScaleX;

                    output.positionCS = clipPosition;
                    #if _OLWVWD_ON

                    output.positionCS.xy += extendDis;
                    #else

                    float ctrl = clamp(1 / output.positionCS.w, 0, 1);

                    output.positionCS.xy += extendDis * output.positionCS.w * ctrl;

                    #endif
        return output;
         }
         float4 frag(Varyings input) : SV_Target {
                 return float4(_OutlineColor.rgb, 1);
         }
         ENDHLSL
         }
        }
            Fallback "Universal Render Pipeline/Lit"
}