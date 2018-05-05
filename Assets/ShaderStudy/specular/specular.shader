// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/specular" {
	Properties{
		_Diffuse("Diffuse", Color) = (1,1,1,1)//材质的漫反射属性
		_Specular("Specular",Color) = (1,1,1,1)//材质的高光属性
		_Gloss("Gloss",Range(8.0,256)) = 20//材质的金属光滑度

	}
		SubShader{
			Pass{
			  Tags {"LightMode" = "ForwardBase"}

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
		  fixed3 color : COLOR;
	  };

	  v2f vert(a2v v) {
		  v2f o;
		  o.pos = UnityObjectToClipPos(v.vertex);

		  fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

		  fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

		  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
		  //漫反射光照
		  fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal, worldLightDir));
		  //计算反射方向的公式 reflect(入射方向，法线方向)
		  fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
		  //计算视角方向:世界空间摄像机的位置-转化到世界空间的顶点坐标
		  fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
		  //高光光照模型
		  fixed3 specular = _LightColor0.rbg*_Specular.rbg*pow(saturate(dot(reflectDir, viewDir)), _Gloss);
		  o.color = diffuse + ambient + specular;
		  return o;
	  }
	  fixed4 frag(v2f i):SV_Target {
		  return fixed4(i.color,1.0);
	  }

		  ENDCG
}

	}
	FallBack "Specular"
}
