Shader "Custom/Reflection" {
	Properties {
		_Color("Color Tint",Color)=(1,1,1,1)
		_ReflectColor("Reflection Color",Color)=(1,1,1,1)
		_ReflectAmount("Reflect Amount",Range(0,1))=1
		_Cubemap("Reflection Cubemap",Cube)="_Skybox"{}

	}
		SubShader{
			Tags {"RenderType" = "Opaque" "Queue" = "Geometry"}

			Pass{
			   CGPROGRAM

			   #pragma multi_compile_fwbase
			   #pragma vertex vert
			   #pragma fragment frag

			   #include "Lighting.cginc"
			   #include "AutoLight.cginc"

			   fixed4 _Color;
	           fixed4 _ReflectColor;//反射的颜色
			   fixed _ReflectAmount;//反射的系数
			   samplerCUBE _Cubemap;//Cubemap纹理

			   struct a2v {
				   float4 vertex:POSITION;
				   float3 normal:NORMAL;
			   };
			   struct v2f {
				   float4 pos:SV_POSITION;
				   float3 worldPos:TEXCOORD0;//世界空间下顶点位置
				   fixed3 worldNormal:TEXCOORD1;//世界空间下法线
				   fixed3 worldViewDir:TEXCOORD2;//世界空间下视线
				   fixed3 worldRefl:TEXCOORD3;//计算反射，并以此来对Cubemap进行采样
				   SHADOW_COORDS(4)
			   };

			   v2f vert(a2v v) {
				   v2f o;
				   o.pos = UnityObjectToClipPos(v.vertex);
				   o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				   o.worldNormal = UnityObjectToWorldNormal(v.normal);
				   o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				   //计算反射
				   o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

				   TRANSFER_SHADOW(o);
				   return o;
			   }
			   fixed4 frag(v2f i) :SV_Target{
				   fixed3 worldNormal = normalize(i.worldNormal);
			       fixed3 worldLightPos = normalize(UnityWorldSpaceLightDir(i.worldPos));
				   fixed3 worldViewDir = normalize(i.worldViewDir);

				   fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				   fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0, dot(worldNormal, worldLightPos));
				   fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb*_ReflectColor.rgb;

				   UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				   fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount)*atten;

				   return fixed4(color, 1.0);
			   }
			  ENDCG
        }

	}
	FallBack "Reflective/VertexLit"
}
