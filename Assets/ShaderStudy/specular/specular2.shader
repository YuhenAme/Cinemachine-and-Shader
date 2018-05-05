// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/specular2" {
	Properties {
		_Diffuse("Diffuse", Color) = (1,1,1,1)//材质的漫反射属性
		_Specular("Specular",Color) = (1,1,1,1)//材质的高光属性
		_Gloss("Gloss",Range(8.0,256)) = 20//材质的金属光滑度
	}
		SubShader{
			Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag
		#include"Lighting.cginc"

		fixed4 _Diffuse;
		fixed4 _Specular;
		float _Gloss;

		//定义顶点输入结构	
		struct a2v {
			float4 vertex:POSITION;
			fixed3 normal : NORMAL;//获取纹理
		};
		//定义片元着色器的输入结构
		struct v2f {
			float4 pos:SV_POSITION;//获取裁剪空间的顶点坐标
			float3 worldNormal : TEXCOORD0;
			float3 worldPos:TEXCOORD1;
		};

		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
			//将模型空间的顶点坐标转换到世界空间
			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			return o;
		}
		fixed4 frag(v2f i) :SV_Target{
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

			//fixed3 halfLambert= dot(worldNormal, worldLightDir)*0.5+0.5
			//半兰伯特模式
			fixed3 halfLambert = dot(worldNormal, worldLightDir)*0.5 + 0.5;
			fixed3 diffuse = _LightColor0.rbg*_Diffuse.rbg*halfLambert;
			//fixed3 diffuse = _LightColor0.rbg*_Diffuse.rbg*saturate(dot(worldNormal, worldLightDir));
			//获取反射方向
			fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
			//获取视角方向 世界空间摄像机的位置-转化到世界空间的顶点坐标
			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

			fixed3 halfDir = normalize(worldLightDir + viewDir);

			//计算高光模型
			//fixed3 specular = _LightColor0.rbg*_Specular.rbg*pow(saturate(dot(reflectDir, viewDir)), _Gloss);
			fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)), _Gloss);

			return fixed4((ambient + diffuse + specular), 1.0);

		}

			ENDCG
		}
	}
		FallBack "Specular"
}
