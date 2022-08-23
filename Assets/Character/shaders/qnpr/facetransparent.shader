Shader "QNPR/FaceTransparent"
{
    Properties
    {
		[Header(MainTex)]
		[Space(10)]
		_MainTex("MainTexture",2D) = "White"{}
		_BaseColor("BaseColor",Color) = (1,1,1,1)
		_AlphaScale("AlphaScale", Range(0,1)) = 1.0

		[Header(BaseDiffuse)]
		[Space(10)]
		_DiffuseColor("DiffuseColor",Color) = (0.7,0.7,0.8,1)
		_DiffuseRange("DiffuseRange",Range(0,1)) = 0.5
		_DiffuseSmooth("DiffuseSmooth",Range(0,1)) = 0.05

		[Header(RimLight)]
		[Space(10)]
		[Toggle(Use_RIM_COLOR)] _UseRimColor("useRimColor",Float) = 0
		_RimColor("RimColor",Color) = (1,0.9,1)
		_RimRange("RimRange",Range(0,5)) = 0.9
		_RimStrength("RimStrength",Range(0,2)) = 0.9

		[Header(Fresnel)]
		[Space(10)]
		_FresnelColor("FresnelColor", Color) = (1,1,1,1)
		_FresnelMin("FresnelMin",Range(0,1)) = 0.48
		_FresnelMax("FresnelMax",Range(0,1)) = 0.59
		_FresnelStrength("FresnelStrength", Range(0, 1)) = 1
				 
		[Header(IlluminationModel)]
		[Space(10)]
		_BoundSharp("BoundSharp",Range(0.001,1)) = 0.01

		[Header(Specular)]
		[Space(5)]
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)
		_SpecularStrength("SpecularStrength",Range(0,1)) = 0.4
		_SpecularRange("SpecularRange",Range(0.001,1)) = 0.01
		[Toggle(USED_ANISOTROPIC)] _EnableAnisotropic("EnableAnisotropic",float) = 0
		[HDR] _AnisotropicColor("Anisotropic Color", Color) = (1, 1, 1)
		_JitterMap("JitterMap",2D) = "white" {}
		_Range("Range",Range(0,2048)) = 2
		_Strength("Strength",Range(0,256)) = 2

		[Header(Shadow)]
		[Space(5)]
		[Toggle(USE_SDF)] _UseSDF("useSDF",Float) = 0
		_FaceShadow("FaceShadowMap",2D) = "white"{}
		_SurShadowColor("SurShadowColor", Color) = (0.55, 0.5, 0.85, 1.0)
		_ShadowColor("ShadowColor", Color) = (0.25, 0.16, 0.56, 1.0)
		_SurShadowRange("SurShadowRange", Range(-0.5, 0.8)) = 0.095
		_ShadowRange("ShadowRange", Range(-1.0, 0.0)) = -0.472
		_Roughness("Roughness",Range(0,10)) = 0
		_ShadowSmooth("ShadowSmooth", Range(0.2,5)) = 0.26
		_ShadowAdjust("ShadowAdjust", Range(0.0,2.0)) = 0.489
	
		[Header(SubsurfaceScattering)]
		[Space(5)]
		_SSSColor("SubsurfaceScatteringColor", Color) = (1,0,0,1)
		_SSSSpecular("SubsurfaceScatteringSpecular", Range(0,1)) = 0.643
		_SSSRange("SubsurfaceScatteringRange", Range(0,1)) = 0.003
		_SSSAdjust("SubsurfaceScatteringAdjust", Range(0,1)) = 0.5

		[Header(HairToFaceShadow)]
		[Toggle(HAIR_SHADOW)] _HairShadow("hairShadow",Float) = 0
		_HairShadowColor("HairShadowColor",Color) = (0.8,0.8,0.9,1)
		_HairShadowDistance("HairShadowDistance",Range(0,0.01)) = 0.002

		[Header(Outline)]
		[Space(10)]
		_OutLineWidth("OutLineWidth",Range(0.01,2)) = 0.24
		_OutLineColor("OutLineColor",Color) = (0.5,0.5,0.5,1)
	}
    SubShader
    {
		Tags { "Queue" = "AlphaTest"}

		LOD 100

			HLSLINCLUDE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

			CBUFFER_START(UnityPerMaterial)

				float4 _MainTex_ST;
				half4 _BaseColor;
				half4 _DiffuseColor;
				half4 _HairShadowColor;
				float _DiffuseRange;
				float _DiffuseSmooth;
				float _OutLineWidth;
				half4 _OutLineColor;
				float _Roughness;
				half4 _SpecularColor;
				float4 _RimColor;
				float _RimSmooth;
				float _RimRange;
				float _RimStrength;
				float _FresnelMin;
				float _FresnelMax;
				float _SpecularRange;
				float _BoundSharp;
				float _SpecularStrength;
				float4 _JitterMap_ST;
				float3 _AnisotropicColor;
				float _Range;
				float _Strength;
				half3 diffuse;
				float _HairShadowDistance;
				half4 tempColor;
				float hairShadow;
				float3 temp;
				half _FresnelStrength;
				half4 _FresnelColor;
				half _ShadowSmooth;
				half _SurShadowRange;
				half _ShadowRange;
				half _ShadowAdjust;
				half4 _SurShadowColor;
				half4 _ShadowColor;
				half4 _SSSColor;
				half _SSSSpecular;
				half _SSSRange;
				half _SSSAdjust;

			CBUFFER_END

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_FaceShadow);
			SAMPLER(sampler_FaceShadow);
			TEXTURE2D(_HairTex);
			SAMPLER(sampler_HairTex);
			TEXTURE2D(_JitterMap);
			SAMPLER(sampler_JitterMap);

			struct a2v
			{

				float4 positionOS:POSITION;

				float4 normalOS:NORMAL;

				float4 tangentOS : TANGENT;

				float2 texcoord:TEXCOORD;

			};

			struct v2f
			{

				float4 positionCS:SV_POSITION;

				float2 texcoord:TEXCOORD;
				
				float3 normalWS:TEXCOORD1;

				float3 positionWS:TEXCOORD2;

				float3 tangentWS : TEXCOORD3;

				float3 BittangentWS : TEXCOORD4;

				float3 positionVS:TEXCOORD5;

				#if HAIR_SHADOW

					float4 positionHS: TEXCOORD6;

					float posNDCw : TEXCOORD7;

				#endif

			};
			real3 SH_IndirectionDiff(float3 normalWS)
			{
				real4 SHCoefficients[7];
				SHCoefficients[0] = unity_SHAr;
				SHCoefficients[1] = unity_SHAg;
				SHCoefficients[2] = unity_SHAb;
				SHCoefficients[3] = unity_SHBr;
				SHCoefficients[4] = unity_SHBg;
				SHCoefficients[5] = unity_SHBb;
				SHCoefficients[6] = unity_SHC;
				float3 Color = SampleSH9(SHCoefficients, normalWS);
				return max(0, Color);
			}

			float Pow2(float x) {
				return x * x;
			}

			float NDCtoNormal(float x) {
				return x * 0.5 + 0.5;
			}

			float NormaltoNDC(float x) {
				return x * 2.0 - 1.0;
			}

			float warp(float p, float q) {
				return (p + q) / (1 + q);
			}

			float3 warp(float3 p, float3 q) {
				return (p + q) / (half3(1.0, 1.0, 1.0) + q);
			}

			float Pow3(float x) {
				return x * x * x;
			}

			float3 Fresnel_attenuation(float VoN, float3 f) {
				return f + (1 - f) * Pow3(1 - VoN);
			}

			float Gaussian(float x, float y, float z) {
				return pow(2.718, -1 * Pow2(x - y) / z);
			}

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

			float3 ShiftTanget(float3 T, float3 N, float shift)
			{
				float3 shiftT = T + shift * N;
				return normalize(shiftT);
			}

			float StrandSpecular(float3 T, float3 V, float3 L, float range, float strength)
			{
				float3 H = normalize(L + V);
				float dotTH = dot(T, H);
				float sinTH = sqrt(1.0 - dotTH * dotTH);
				float dirAtten = smoothstep(-1.0, 0.0, dotTH);
				return dirAtten * pow(sinTH, range) * strength;

			}

		ENDHLSL

		pass
		{
			//ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
				#pragma vertex VERT
				#pragma fragment FRAG


				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
				#pragma multi_compile _ _SHADOWS_SOFT//  
				#pragma multi_compile_fog

				#pragma shader_feature HAIR_SHADOW
				#pragma shader_feature USE_SDF
				#pragma shader_feature Use_RIM_COLOR
				#pragma shader_feature_local_fragment USED_ANISOTROPIC

				float _AlphaScale;

				v2f VERT(a2v i)

				{
					v2f o;

					VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
					o.positionCS = positionInputs.positionCS;
					o.positionWS = positionInputs.positionWS;

					o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);

					VertexNormalInputs tbn = GetVertexNormalInputs(i.normalOS, i.tangentOS);
					o.normalWS = tbn.normalWS;
					o.tangentWS = tbn.tangentWS;
					o.BittangentWS = tbn.bitangentWS;

					#if HAIR_SHADOW
						o.posNDCw = positionInputs.positionNDC.w;
						o.positionHS = ComputeScreenPos(o.positionCS);
					#endif
					return o;
				}

				half4 FRAG(v2f i) :SV_TARGET
				{
					half4 col = 1;
					half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord) * _BaseColor;

					half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
					half3 normalWS = normalize(i.normalWS);
					float3 worldBittangent = normalize(i.BittangentWS);

					float4 shadowCoords = TransformWorldToShadowCoord(i.positionWS.xyz);
					Light mainLight = GetMainLight(shadowCoords);
					float3 lightDir = mainLight.direction;
					float3 mainLightDir = normalize(mainLight.direction);

					half halfLambert = (dot(normalWS, mainLightDir) * 0.5 + 0.5);
					half ramp = smoothstep(0, _DiffuseSmooth, halfLambert - _DiffuseRange);
					float lightAtten = 1 - ramp;

					diffuse = lerp(_DiffuseColor, _BaseColor, ramp);
					diffuse *= tex;
					diffuse *= mainLight.color;

					half NdotL = max(0, dot(normalWS, mainLightDir));
					half VdotN = dot(viewDirWS, normalWS);
					half f = 1.0 - saturate(VdotN);
					half rimBloom = pow(f, _RimRange) * _RimStrength * NdotL;
					half3 rimColor = f * _RimColor.rgb * _RimColor.a * mainLight.color * rimBloom;

					#if USE_SDF
						half SDFTex = SAMPLE_TEXTURE2D(_FaceShadow, sampler_FaceShadow, i.texcoord);
						half SDFTexL = SAMPLE_TEXTURE2D(_FaceShadow, sampler_FaceShadow, float2(-i.texcoord.x, i.texcoord.y));

						float RdotL = dot(lightDir.x, mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 1.0)).x);
						float angle = dot(lightDir.xz, mul(unity_ObjectToWorld, float4(0.0, 0.0, 1.0, 1.0)).xz);
						angle = (angle + 1) / 2;

						if (RdotL < 0) {
							SDFTex = SDFTexL;
						}
						else {
							SDFTex = SDFTex;
						}
						SDFTex = SDFTex > angle ? 0.0 : 1.0;

						float3 Up = float3(0.0, 1.0, 0.0);
						float3 Front = unity_ObjectToWorld._12_22_32;
						float3 Right = cross(Up, Front);
						float switchShadow = dot(normalize(Right.xz), normalize(lightDir.xz)) * 0.5 + 0.5 < 0.5;
						float FaceShadow = lerp(SDFTex.r, 1 - SDFTex, switchShadow.r);
						float SDFRange = dot(normalize(Front.xz), normalize(lightDir.xz));
						lightAtten = 1 - smoothstep(SDFRange - 0.1, SDFRange + 0.1, SDFTex);

						diffuse = lerp(_DiffuseColor, _BaseColor, SDFTex);
						diffuse *= tex;
						diffuse *= mainLight.color;
					#endif

					hairShadow = 1;

					#if HAIR_SHADOW
						float depth = (i.positionCS.z / i.positionCS.w);
						float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
						float2 scrPos = i.positionHS.xy / i.positionHS.w;
						float3 viewLightDir = normalize(TransformWorldToViewDir(mainLight.direction)) * (1 / min(i.posNDCw, 1)) * min(1, 5 / linearEyeDepth);
						float2 samplingPoint = scrPos + _HairShadowDistance * viewLightDir.xy;
						float hairDepth = SAMPLE_TEXTURE2D(_HairTex, sampler_HairTex, samplingPoint).g;
						hairDepth = LinearEyeDepth(hairDepth, _ZBufferParams);
						hairShadow = linearEyeDepth > hairDepth * smoothstep(1.6, 1.51, i.positionWS.y) - 0.01 ? 0 : 1;
					#endif
					tempColor = _DiffuseColor;
					tempColor /= 100;
					float3 hairS = lerp(_HairShadowColor, _BaseColor, hairShadow);

					half3 H = normalize(mainLightDir + viewDirWS);
					half NoL = dot(normalWS, mainLightDir);
					half NoH = dot(normalWS, H);
					half NoV = dot(normalWS, viewDirWS);
					half VoL = dot(viewDirWS, mainLightDir);
					half VoH = dot(viewDirWS, H);

					half roughness = 0.95 - 0.95 * _Roughness;
					half _BoundSharp = 9.5 * Pow2(roughness - 1) + 0.5;

					half NDF0 = D_GGX_DIY(roughness * roughness, 1);
					half NDF_Bound = NDF0 * _SpecularRange;
					half NDF = D_GGX_DIY(roughness * roughness, clamp(0, 1, NoH)) + 0.341 * (lightAtten - 1);

					half specularWin = sigmoid(NDF, NDF_Bound, _BoundSharp * _ShadowSmooth);
					half specular = specularWin * (NDF0 + NDF_Bound) / 2 * _SpecularStrength * _SpecularColor;

					#if USED_ANISOTROPIC
						float4 JitterMap = SAMPLE_TEXTURE2D(_JitterMap, sampler_JitterMap, i.texcoord * _JitterMap_ST.xy + _JitterMap_ST.zw);
						worldBittangent = ShiftTanget(worldBittangent, normalWS, JitterMap.x);
						float JitterSpecular = StrandSpecular(worldBittangent, viewDirWS, mainLightDir, _Range, _Strength);
						specular = saturate(JitterSpecular * ramp) * tex.xyz * _AnisotropicColor.rgb;
					#endif

					float x = diffuse.g;
					half Lambert = NoL + _ShadowAdjust * NormaltoNDC(x) + 0.341 * (lightAtten - 1);

					half SurShadow = sigmoid(Lambert, _SurShadowRange, _BoundSharp * _ShadowSmooth);
					half Shadow = sigmoid(Lambert, _ShadowRange, _BoundSharp * _ShadowSmooth);

					#if USE_SDF
						half Lambert2 = NoL + _ShadowAdjust * NormaltoNDC(SDFTex) + 0.341 * (lightAtten - 1);
						Shadow = sigmoid(Lambert2, _ShadowRange, _BoundSharp * _ShadowSmooth);
					#endif

					half SurShadowL = SurShadow;
					half SurShadowD = Shadow - SurShadow;
					half DarkShadow = 1 - Shadow;

					half shadow1 = (1 + NDCtoNormal(_SurShadowRange)) / 2;
					half shadow2 = (NDCtoNormal(_SurShadowRange) + NDCtoNormal(_ShadowRange)) / 2;
					half shadow3 = (NDCtoNormal(_ShadowRange));
					half dB = 1.0;
					half3 shadowColor1 = SurShadowL * shadow1.xxx;
					half3 shadowColor2 = SurShadowD * shadow2.xxx * _SurShadowColor.rgb * 3 / (_SurShadowColor.r + _SurShadowColor.g + _SurShadowColor.b);
					half3 shadowColor3 = DarkShadow * shadow3.xxx * _ShadowColor.rgb * 3 / (_ShadowColor.r + _ShadowColor.g + _ShadowColor.b);
					half3 shadowColor = warp(shadowColor1 + shadowColor2 + shadowColor3, dB.xxx);

					half3 diffuseResult1 = shadowColor * tex.rgb;
					diffuseResult1 *= hairS;

					half SSSurShadowL = Gaussian(Lambert, _SurShadowRange, _SSSAdjust * _SSSRange);
					half SSSurShadowD = Gaussian(Lambert, _SurShadowRange, _SSSRange);
					half3 SSTex1 = (SurShadowL * shadow2) * _SSSAdjust * SSSurShadowL;
					half3 SSTex2 = ((SurShadowD + DarkShadow) * shadow2) * SSSurShadowD;
					half3 SSSResult = _SSSSpecular * (SSTex1 + SSTex2) * _SSSColor.rgb;

					half3 fresnelAtten = Fresnel_attenuation(NoV, float3(0.1, 0.1, 0.1));
					float FresnelRange = smoothstep(_FresnelMin, _FresnelMax, fresnelAtten);
					float3 Fresnel = _FresnelStrength * FresnelRange * (1 - VoL) / 2 * _FresnelColor.rgb * _FresnelColor.a;

					half3 ResultColor = specular * mainLight.color + (1 - specular) * diffuseResult1.rgb * mainLight.color + SSSResult + Fresnel;

					#if Use_RIM_COLOR
						ResultColor += rimColor;
					#endif

					return half4(ResultColor.rgb, tex.a * _AlphaScale);
				}

			ENDHLSL

		}

		UsePass "Universal Render Pipeline/Lit/ShadowCaster"

	}


	FallBack "Transparent/Cutout/VertexLit"


}
