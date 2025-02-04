﻿Shader "Universal Render Pipeline/Custom/ShadowsAR"
{
	Properties
	{
		_ShadowTransparency("Transparency", Range(0, 1)) = 1
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "AlphaTest"
			"RenderPipeline" = "UniversalPipeline"
			"IgnoreProjector" = "True"
		}

		// Shadow only pass
		Pass
		{
			Name "Shadows AR"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// #pragma enable_d3d11_debug_symbols

			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float _ShadowTransparency;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS   : POSITION;
			};

			struct v2f
			{
				float4 positionCS   : SV_POSITION;
				float3 positionWS   : TEXCOORD0;
				float4 shadowCoord  : TEXCOORD1;
			};

			v2f vert(Attributes input)
			{
				v2f output = (v2f)0;
				// Positionen berechnen
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				// Speichern
				output.shadowCoord = GetShadowCoord(vertexInput);
				output.positionCS = vertexInput.positionCS;
				output.positionWS = vertexInput.positionWS;
				// An Fragment weitergeben
				return output;
			}

			half4 frag(v2f input) : SV_Target
			{
				// Main Light Attenuation bestimmen
				half shadowAtten = MainLightRealtimeShadow(input.shadowCoord);
				// Additional Light Attenuation bestimmen
				uint lightsCount = GetAdditionalLightsCount();
				// Maximalen Schatten nehmen
				for (uint lightIndex = 0u; lightIndex < lightsCount; lightIndex++)
				{
					shadowAtten = min(shadowAtten, AdditionalLightRealtimeShadow(lightIndex, input.positionWS));
				}
				// Clip falls kein Schatten (-> Schatten != 0)
				clip(-shadowAtten);
				// Schwarz zurueck
				return half4(0, 0, 0, _ShadowTransparency);
			}

			ENDHLSL
		}
	}
	// Error
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
