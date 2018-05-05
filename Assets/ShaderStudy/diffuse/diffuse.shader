// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//简单的漫反射shader，顶点着色器中计算光照模型
Shader "Custom/diffuse" {
	Properties{
		//漫反射的系数
		_Diffuse("Diffuse",Color) = (1,1,1,1)
	}
		SubShader{
			Pass{
			   Tags{"LightMode" = "ForwardBase"}//定义在Unity的光照流水线的角色

			   CGPROGRAM
			   #pragma vertex vert
			   #pragma fragment frag
			   #include"Lighting.cginc"//导入内置文件

			fixed4 _Diffuse;//获得漫反射属性
	//定义顶点着色器的输入结构
	struct a2v {
		float4 vertex:POSITION;
		float3 normal:NORMAL;
			};
	//定义片元着色器的输入结构
	struct v2f {
		float4 pos:SV_POSITION;
		fixed3 color : COLOR;
	};
	//定点着色器
	v2f vert(a2v v) {
		v2f o;
		//获取模型在裁剪空间的定点坐标，并且赋给o.pos
		//o.pos = UnityObjectToClipPos(v.vertex);
		o.pos = UnityObjectToClipPos(v.vertex);
		//获得环境光
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

		//将模型的法线转换到世界空间，再做归一化处理
		fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
		//将光照的方向转换到世界空间，在做归一化处理
		fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
		//标准光照模型= 环境光颜色*漫反射属性*MAX(点积(表面法线,光照方向))
		fixed3 diffuse = _LightColor0.rbg*_Diffuse.rbg*saturate(dot(worldNormal, worldLight));

		//输出光=环境光+漫反射光
		o.color = ambient + diffuse;

		return o;
	}


	//片元着色器
	fixed4 frag(v2f i) :SV_Target{
		return fixed4(i.color,1.0);
	}
		ENDCG
}
    
	}
	FallBack "Diffuse"
}
