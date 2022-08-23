Shader "QNPR/Hairpin"
{

Properties

{
	_MainTex("MainTex",2D) = "White"{}

	_BaseColor("BaseColor",Color) = (1,1,1,1)
	_ShadowColor("ShadowColor",Color) = (0.7,0.7,0.8,1)
	_ShadowRange("ShadowRange",Range(0,1)) = 0.5
	_ShadowSmooth("ShadowSmooth",Range(0,1)) = 0.05

	_SpecularColor("SpecularColor",Color) = (0.5,0.5,0.2)

	_shadowControl("ShadowControl",Range(0,2)) = 1.5

	_Roughness("Roughness",Range(0.001,1)) = 0.01
	_DividLineSpec("SpecularRange",Range(0.001,1)) = 0.01

   _BoundSharp("BoundSharp",Range(0.001,1)) = 0.01
		_speColor("SpecularColor",Color) = (1,1,1)
		_speStrength("SpecularStrength",Range(0,1)) = 0.4

		 [Header(Outline)]
		[Space(10)]
		_Outlinewidth("Outline Width", Range(0,1)) = 0.4
		_OutlineColor("Outline Color", Color) = (0.5,0.5,0.5,1)
}

SubShader

		{

			Tags{

			"RenderPipeline" = "UniversalRenderPipeline"

			"RenderType" = "Opaque"

			}

			HLSLINCLUDE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial)

			float4 _MainTex_ST;
			half4 _BaseColor;
			half4 _ShadowColor;
			float _ShadowRange;
			float _ShadowSmooth;

			half4 _SpecularColor;
			float _shadowControll;
			float _Roughness;
			float _DividLineSpec;
			float _BoundSharp;
			half3 _speColor;
			float _speStrength;

			float _Outlinewidth;
			float4 _OutlineColor;
			CBUFFER_END

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			 struct a2v

			 {

				 float4 positionOS:POSITION;

				 float4 normalOS:NORMAL;

				 float2 texcoord:TEXCOORD;

			 };

			 struct v2f

			 {

				 float4 positionCS:SV_POSITION;
				 float2 texcoord:TEXCOORD;
				 float3 normalWS:TEXCOORD1;
				 float3 positionWS:TEXCOORD2;

			 };

			 float D_GGX_DIY(float a2, float NoH) {
				 float d = (NoH * a2 - NoH) * NoH + 1;
				 return a2 / (3.14159 * d * d);
			 }

			 float sigmoid(float x, float y, float z) {
				 float s;
				 float q;
				 q = pow(100000, (-3 * z * (x - y))) + 1;
				 s = 1 / q;
				 return s;
			 }
			ENDHLSL



				pass
			{


				HLSLPROGRAM
				#pragma vertex VERT
				#pragma fragment FRAG

				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				#pragma multi_compile _ _SHADOWS_SOFT//  



				v2f VERT(a2v i)

				{
					v2f o;
					o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
					o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);
					o.normalWS = TransformObjectToWorldNormal(i.normalOS);
					o.positionWS = TransformObjectToWorld(i.positionOS);
					return o;

				}

				half4 FRAG(v2f i) :SV_TARGET

				{
					half4 col = 1;

					half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord) * _BaseColor;

					half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
					half3 normalWS = normalize(i.normalWS);
					Light mainLight = GetMainLight();
					float3 mainLightDir = normalize(mainLight.direction);
					half halfLambert = (dot(normalWS, mainLightDir) * 0.5 + 0.5);


					
					half ramp = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowRange);
					half3 diffuse = lerp(_ShadowColor, _BaseColor, ramp);
					diffuse *= tex;
					diffuse *= mainLight.color;


					//specular
					half3 H = normalize(mainLightDir + viewDirWS);
					half NoH = dot(normalWS, H);
					half NDF0 = D_GGX_DIY(_Roughness * _Roughness, 1);
					half NDF_Bound = NDF0 * _DividLineSpec;
					half NDF = D_GGX_DIY(_Roughness * _Roughness, clamp(0, 1, NoH));

					half specularWin = sigmoid(NDF, NDF_Bound, _BoundSharp);

					half specular = specularWin * (NDF0 + NDF_Bound) / 2 * _speStrength * _speColor;


					float4 finalColor = float4(diffuse + specular,1);
					return  finalColor;

						}

						ENDHLSL

					}
			Pass
			{
				Cull Front
				Name "Outline"

				HLSLPROGRAM

					#pragma vertex vertOutline 
					#pragma fragment fragOutline

					float4 vertOutline(float4 positionOS : POSITION , float3 normal : NORMAL) : SV_POSITION
					{
						VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOS.xyz);
						float4 outlinePos = positionInputs.positionCS;
						float3 normalView = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, normal));
						float3 worldNormal = normalize(mul((float3x3)UNITY_MATRIX_P, normalView).xyz);
						float4 scaledScreenParams = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
						float ScaleX = abs(scaledScreenParams.y / scaledScreenParams.x);
						worldNormal.x *= ScaleX;
						float ctrl = clamp(1 / outlinePos.w, 0, 1);
						worldNormal.z -= 0.4;
						outlinePos.xyz += (0.01 * _Outlinewidth * outlinePos.w * ctrl) * worldNormal.xyz;

						return outlinePos;
					}

					float4 fragOutline(a2v i) : COLOR
					{
						float4 MainTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
						float4 OutlineColor = _OutlineColor * MainTexture;
						return OutlineColor;
					}
				ENDHLSL
			}

						UsePass "Universal Render Pipeline/Lit/ShadowCaster"
		}

}
