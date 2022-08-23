Shader "QNPR/Fur"
{
	Properties
	{
	   [Header(Macro)]
		[Header(Main)]
		[MainColor]_Color("Color", Color) = (1,1,1,1)
		_MainTex("Maintexture", 2D) = "white" {}

		_BumpMap("Normal Map", 2D) = "bump" {}

		[Space(20)]
		_FurScatterColor("FurScatterColor", Color) = (1,0.75,0.79,1)
		_FurScatterScale("FurScatterStrength", Range(0, 1)) = 1

		[Space(20)]
		_LayerTex("FurTex", 2D) = "white" {}
		_FurSize("FurSize", Range(.0002, 0.1)) = 0.06
		_FurThickness("FurThickness", Range(0,1)) = 0.744 

		_Force("ForceDirection", Vector) = (0,0,0,0)
		_ForceStrength("ForceStrength", Range(0,1)) = 1
		_DirectionMap("DirectionMap", 2D) = "white"{}
		_DirectionAdjust("DirectionAdjust",Range(0,1)) = 0.398
		[Header(Shadow)]
		_ShadowColor("ShadowColor", Color) = (0,0,0,0)
		_ShadowStrength("ShadowStrength",Range(0,1)) = 1

	}
		SubShader
			{
				Tags { "RenderType" = "Opaque"  "PerformanceChecks" = "False"}

				LOD 100
				HLSLINCLUDE
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				#define UNITY_SETUP_BRDF_INPUT MetallicSetup

				#define _FABRIC_URP 1
				#define _FUR_URP 1

				sampler2D _LayerTex;
				sampler2D   _BumpMap;
				sampler2D _DirectionMap;
				sampler2D _MainTex;
				sampler2D   _OcclusionMap;

				CBUFFER_START(UnityPerMaterial)
				half _DirectionAdjust;
				half3 _FurScatterColor;
				half  _FurScatterScale;
				float4 _MainTex_ST;
				float4 _LayerTex_ST;
				half _Glossiness;
				half _FurSize;
				half _ForceStrength;
				half4 _Color;
				half3 _Force;
				half _FurThickness;

				half        _OcclusionStrength;
				half        _BumpScale;
				float _Metallic;

				// //PBR
				float3 _Albedo;

				float3 _Specular;
				float _Smoothness;
				float _Occlusion;
				float3 _Emission;
				float _Alpha;
				float4 _ShadowColor;
				half _ShadowStrength;
				CBUFFER_END
				half _FUR_OFFSET;

				//
				ENDHLSL
					Pass
				{
				   Name "FurRender"
					Tags{ "LightMode" = "FurRendererBase"}

					ZWrite On
					//Blend SrcAlpha OneMinusSrcAlpha
					HLSLPROGRAM

					#pragma multi_compile_fog
					#pragma multi_compile _ LIGHTMAP_ON
					#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
					#pragma shader_feature _NORMALMAP
					#pragma shader_feature _EMISSION
					#pragma shader_feature _METALLICGLOSSMAP
					#pragma shader_feature ___ _DETAIL_MULX2
					#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
					#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
					#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF

					#pragma vertex vert_LayerBase
					#pragma fragment frag_LayerBase

					struct a2v
					{
						float4 positionOS: POSITION;
						float2 texcoord : TEXCOORD0;
						half2 lightmapUV : TEXCOORD1;
						float4 tangentOS : TANGENT;
						float3 normalOS : NORMAL;
					};

					struct v2f
					{
						float4 positionCS : SV_POSITION;
						float4 texcoord : TEXCOORD0;
						float3 positionWS : TEXCOORD1;
						float3 viewDirWS : TEXCOORD2;
						float4 tangentToWorldAndPackedData[3] : TEXCOORD3;
						half4  UVmap : TEXCOORD6;
						float3 normalWS : TEXCOORD7;
						float4 shadowCoord : TEXCOORD8;
						float4 lightmapUVOrVertexSH : TEXCOORD9;
						float3 viewWS : TEXCOORD10;
						half4 fogFactorAndVertexLight : TEXCOORD11;
						float4 screenPos : TEXCOORD12;

					};

					#include "UtilsInclude.hlsl"

					v2f vert(a2v IN, half FUR_OFFSET = 0)
					{
						UNITY_SETUP_INSTANCE_ID(IN);
						v2f OUT;
						OUT = (v2f)0;
						UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);


						half3 furdirection = lerp(IN.normalOS, _Force * _ForceStrength + IN.normalOS * (1 - _ForceStrength), _FUR_OFFSET);

						IN.positionOS.xyz += furdirection * _FurSize * _FUR_OFFSET;
						OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
						float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
						float4 positionCS = TransformWorldToHClip(positionWS);
						OUT.screenPos = ComputeScreenPos(positionCS);

						OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
						OUT.texcoord.xy = TRANSFORM_TEX(IN.texcoord, _MainTex);
						OUT.viewWS = normalize(_WorldSpaceCameraPos - OUT.positionWS);
						VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
						half3 vertexLight = VertexLighting(positionWS, normalInput.normalWS);
						half fogFactor = ComputeFogFactor(positionCS.z);
						OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
						OUT.viewDirWS = NormalizePerVertexNormal(OUT.positionWS.xyz - _WorldSpaceCameraPos);
						half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
						OUT.normalWS = normalWS;

							float4 tangentWorld = float4(TransformObjectToWorldDir(IN.tangentOS.xyz), IN.tangentOS.w);
							float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWS, tangentWorld.xyz, tangentWorld.w);
							OUT.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
							OUT.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
							OUT.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];


						#ifdef _PARALLAXMAP
							TANGENT_SPACE_ROTATION;
							half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(IN.positionOS));
							OUT.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
							OUT.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
							OUT.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
						#endif

						VertexPositionInputs vertexInput = (VertexPositionInputs)0;
						vertexInput.positionWS = positionWS;
						vertexInput.positionCS = positionCS;
						OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUVOrVertexSH.xy);
						OUTPUT_SH(normalWS, OUT.lightmapUVOrVertexSH.xyz);

						OUT.UVmap = VertexGIForward(IN, OUT.positionWS, normalWS);

						OUT.shadowCoord = GetShadowCoord(vertexInput);
						OUT.shadowCoord = TransformWorldToShadowCoord(positionWS);

						return OUT;
					}

					half4 frag(v2f IN, half FUR_OFFSET = 0) : SV_Target
					{
						float3 Albedo = float3(0.5, 0.5, 0.5);
						float Metallic = 0;
						float3 Specular = 0.5;
						float Smoothness = 0.5;
						float Occlusion = 1;
						float3 Emission = 0;
						float Alpha = 1;
						float3 BakedGI = 0;

						InputData inputData;
						inputData.positionWS = IN.positionWS;
						inputData.viewDirectionWS = IN.viewWS;
						inputData.shadowCoord = IN.shadowCoord;
						inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
						inputData.normalWS = IN.normalWS;
						inputData.fogCoord = IN.fogFactorAndVertexLight.x;
						inputData.bakedGI = 0;

						inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, IN.normalWS);


						half4 color = UniversalFragmentPBR(
						inputData,
						_Albedo,
						_Metallic,
						_Specular,
						_Smoothness,
						_Occlusion,
						_Emission,
						_Alpha);

						#ifdef _REFRACTION_ASE
							float4 aspect = ScreenPos / ScreenPos.w;
							float3 refractionOffset = (RefractionIndex - 1.0) * mul(UNITY_MATRIX_V, WorldNormal).xyz * (1.0 - dot(WorldNormal, WorldViewDirection));
							aspect.xy += refractionOffset.xy;
							float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR(aspect) * RefractionColor;
							color.rgb = lerp(refraction, color.rgb, color.a);
							color.a = 1;
						#endif

						#ifdef ASE_FOG
							#ifdef TERRAIN_SPLAT_ADDPASS
								color.rgb = MixFogColor(color.rgb, half3(0, 0, 0), IN.fogFactorAndVertexLight.x);
							#else
								color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
							#endif
						#endif

						half facing = dot(-IN.viewDirWS, IN.tangentToWorldAndPackedData[2].xyz);
						facing = saturate(ceil(facing)) * 2 - 1;

						FRAGMENT_SETUP(s)
						UNITY_SETUP_INSTANCE_ID(IN);
						UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

						Light mainLight = GetMainLight(IN.shadowCoord);
						half occlusion = CalOcclusion(IN.texcoord.xy);

						BRDFData brdfData;
						half3 albedo = 0.5;
						half3 specular = .5;
						half brdfAlpha = 1;
						InitializeBRDFData(albedo,0,specular,0.5, brdfAlpha, brdfData);

						half lightAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

						half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
						half3 radiance = mainLight.color * (lightAttenuation * NdotL);


						half4 c = FABRIC_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.viewDirWS, mainLight, inputData, lightAttenuation);

						c.rgb += CalEmission(IN.texcoord.xy);

						float2 uvoffset = tex2D(_DirectionMap, IN.texcoord.xy).rg * 2 - 1;

						half alpha = tex2D(_LayerTex, TRANSFORM_TEX(IN.texcoord.xy, _LayerTex) + _DirectionAdjust * uvoffset * _FUR_OFFSET).r;
						alpha = step(lerp(0, _FurThickness, _FUR_OFFSET), alpha);
						c.a = 1 - _FUR_OFFSET * _FUR_OFFSET;
						c.a += dot(-s.viewDirWS, s.normalWorld) - 1;
						c.a = max(0, c.a);
						c.a *= alpha;
						c = half4(c.rgb * lerp(lerp(_ShadowColor.rgb, 1, _FUR_OFFSET), 1, _ShadowStrength), c.a);

						return c;
					}
					v2f vert_LayerBase(a2v i)
					{
						return vert(i, 0);
					}
					v2f vert_Layer(a2v i)
					{
						return vert(i, 0.1);
					}
					half4 frag_LayerBase(v2f i) : SV_Target
					{
						return frag(i, 0);
					}
					half4 frag_Layer(v2f i) : SV_Target
					{
						return frag(i, 0.1);
					}


					ENDHLSL
				}
				Pass
				{
				   Name "FurRender"
					Tags{ "LightMode" = "FurRendererLayer"}
					Blend SrcAlpha OneMinusSrcAlpha
					ZWrite On
					HLSLPROGRAM

					#pragma multi_compile_fog
					#pragma multi_compile _ LIGHTMAP_ON
					#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
					#pragma shader_feature _NORMALMAP

					#pragma shader_feature _EMISSION
					#pragma shader_feature _METALLICGLOSSMAP
					#pragma shader_feature ___ _DETAIL_MULX2
					#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
					#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
					#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF

					#pragma vertex vert_LayerBase
					#pragma fragment frag_LayerBase

					struct a2v
					{
						float4 positionOS: POSITION;
						float2 texcoord : TEXCOORD0;
						half2 lightmapUV : TEXCOORD1;
						float4 tangentOS : TANGENT;
						float3 normalOS : NORMAL;
					};

					struct v2f
					{
						float4 positionCS : SV_POSITION;
						float4 texcoord : TEXCOORD0;
						float3 positionWS : TEXCOORD1;
						float3 viewDirWS : TEXCOORD2;
						float4 tangentToWorldAndPackedData[3] : TEXCOORD3;
						half4  UVmap : TEXCOORD6;
						float3 normalWS : TEXCOORD7;
						float4 shadowCoord : TEXCOORD8;
						float4 lightmapUVOrVertexSH : TEXCOORD9;
						float3 viewWS : TEXCOORD10;
						half4 fogFactorAndVertexLight : TEXCOORD11;
						float4 screenPos : TEXCOORD12;

					};

					#include "UtilsInclude.hlsl"

					v2f vert(a2v IN, half FUR_OFFSET = 0)
					{
						UNITY_SETUP_INSTANCE_ID(IN);
						v2f OUT;
						OUT = (v2f)0;
						UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);


						half3 furdirection = lerp(IN.normalOS, _Force * _ForceStrength + IN.normalOS * (1 - _ForceStrength), _FUR_OFFSET);

						IN.positionOS.xyz += furdirection * _FurSize * _FUR_OFFSET;
						OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
						float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
						float4 positionCS = TransformWorldToHClip(positionWS);
						OUT.screenPos = ComputeScreenPos(positionCS);

						OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
						OUT.texcoord.xy = TRANSFORM_TEX(IN.texcoord, _MainTex);
						OUT.viewWS = normalize(_WorldSpaceCameraPos - OUT.positionWS);
						VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
						half3 vertexLight = VertexLighting(positionWS, normalInput.normalWS);
						half fogFactor = ComputeFogFactor(positionCS.z);
						OUT.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
						OUT.viewDirWS = NormalizePerVertexNormal(OUT.positionWS.xyz - _WorldSpaceCameraPos);
						half3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
						OUT.normalWS = normalWS;

							float4 tangentWorld = float4(TransformObjectToWorldDir(IN.tangentOS.xyz), IN.tangentOS.w);
							float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWS, tangentWorld.xyz, tangentWorld.w);
							OUT.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
							OUT.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
							OUT.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];


						#ifdef _PARALLAXMAP
							TANGENT_SPACE_ROTATION;
							half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(IN.positionOS));
							OUT.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
							OUT.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
							OUT.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
						#endif

						VertexPositionInputs vertexInput = (VertexPositionInputs)0;
						vertexInput.positionWS = positionWS;
						vertexInput.positionCS = positionCS;
						OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUVOrVertexSH.xy);
						OUTPUT_SH(normalWS, OUT.lightmapUVOrVertexSH.xyz);

						OUT.UVmap = VertexGIForward(IN, OUT.positionWS, normalWS);

						OUT.shadowCoord = GetShadowCoord(vertexInput);
						OUT.shadowCoord = TransformWorldToShadowCoord(positionWS);

						return OUT;
					}

					half4 frag(v2f IN, half FUR_OFFSET = 0) : SV_Target
					{
						float3 Albedo = float3(0.5, 0.5, 0.5);
						float Metallic = 0;
						float3 Specular = 0.5;
						float Smoothness = 0.5;
						float Occlusion = 1;
						float3 Emission = 0;
						float Alpha = 1;
						float3 BakedGI = 0;

						InputData inputData;
						inputData.positionWS = IN.positionWS;
						inputData.viewDirectionWS = IN.viewWS;
						inputData.shadowCoord = IN.shadowCoord;
						inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
						inputData.normalWS = IN.normalWS;
						inputData.fogCoord = IN.fogFactorAndVertexLight.x;
						inputData.bakedGI = 0;

						inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, IN.normalWS);


						half4 color = UniversalFragmentPBR(
						inputData,
						_Albedo,
						_Metallic,
						_Specular,
						_Smoothness,
						_Occlusion,
						_Emission,
						_Alpha);

						#ifdef _REFRACTION_ASE
							float4 aspect = ScreenPos / ScreenPos.w;
							float3 refractionOffset = (RefractionIndex - 1.0) * mul(UNITY_MATRIX_V, WorldNormal).xyz * (1.0 - dot(WorldNormal, WorldViewDirection));
							aspect.xy += refractionOffset.xy;
							float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR(aspect) * RefractionColor;
							color.rgb = lerp(refraction, color.rgb, color.a);
							color.a = 1;
						#endif

						#ifdef ASE_FOG
							#ifdef TERRAIN_SPLAT_ADDPASS
								color.rgb = MixFogColor(color.rgb, half3(0, 0, 0), IN.fogFactorAndVertexLight.x);
							#else
								color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
							#endif
						#endif

						half facing = dot(-IN.viewDirWS, IN.tangentToWorldAndPackedData[2].xyz);
						facing = saturate(ceil(facing)) * 2 - 1;

						FRAGMENT_SETUP(s)
						UNITY_SETUP_INSTANCE_ID(IN);
						UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

						Light mainLight = GetMainLight(IN.shadowCoord);
						half occlusion = CalOcclusion(IN.texcoord.xy);

						BRDFData brdfData;
						half3 albedo = 0.5;
						half3 specular = .5;
						half brdfAlpha = 1;
						InitializeBRDFData(albedo,0,specular,0.5, brdfAlpha, brdfData);

						half lightAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

						half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
						half3 radiance = mainLight.color * (lightAttenuation * NdotL);


						half4 c = FABRIC_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.viewDirWS, mainLight, inputData, lightAttenuation);

						c.rgb += CalEmission(IN.texcoord.xy);

						float2 uvoffset = tex2D(_DirectionMap, IN.texcoord.xy).rg * 2 - 1;

						half alpha = tex2D(_LayerTex, TRANSFORM_TEX(IN.texcoord.xy, _LayerTex) + _DirectionAdjust * uvoffset * _FUR_OFFSET).r;
						alpha = step(lerp(0, _FurThickness, _FUR_OFFSET), alpha);
						c.a = 1 - _FUR_OFFSET * _FUR_OFFSET;
						c.a += dot(-s.viewDirWS, s.normalWorld) - 1;
						c.a = max(0, c.a);
						c.a *= alpha;
						c = half4(c.rgb * lerp(lerp(_ShadowColor.rgb, 1, _FUR_OFFSET), 1, _ShadowStrength), c.a);

						return c;
					}
					v2f vert_LayerBase(a2v i)
					{
						return vert(i, 0);
					}
					v2f vert_Layer(a2v i)
					{
						return vert(i, 0.1);
					}
					half4 frag_LayerBase(v2f i) : SV_Target
					{
						return frag(i, 0);
					}
					half4 frag_Layer(v2f i) : SV_Target
					{
						return frag(i, 0.1);
					}


					ENDHLSL
				}
				

				
				UsePass "Universal Render Pipeline/Lit/ShadowCaster"
					UsePass "Universal Render Pipeline/Lit/DepthOnly"
			}
}
