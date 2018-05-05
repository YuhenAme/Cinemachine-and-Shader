// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//简单的漫反射shader,用半兰伯特公式在片元着色器下计算光照模型
Shader "Custom/HalfLambert" {
	Properties{
		_Diffuse("Diffuse",Color) = (1,1,1,1)

	}
		SubShader{
			Pass{
			  Tags{"LightMode" = "ForwardBase"}//定义在光照流水线的角色

			  CGPROGRAM
			  #pragma vertex vert
			  #pragma fragment frag

			  #include "Lighting.cginc"

			fixed4 _Diffuse;

	//顶点着色器输入结构体
	struct a2v {
		float4 vertex :POSITION;
		float3 normal :NORMAL;//获取模型的法线
			};
	//顶点着色器的输出结构体
	struct v2f {
		float4 pos:SV_POSITION;
		float3 worldNormal:TEXCOORD0;
	};
	//顶点着色器
	v2f vert(a2v v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
		return o;
	}
	//片元着色器
	fixed4 frag(v2f i) :SV_Target{
		//获取环境光
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
	    //归一化
	    fixed3 worldNormal = normalize(i.worldNormal);
		//获取世界坐标的光照方向再做归一化处理
		fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
		//半兰伯特公式
		fixed3 halfLambert = dot(worldNormal, worldLightDir)*0.5 + 0.5;
		//获取漫反射光照
		fixed3 diffuse = _LightColor0.rbg*_Diffuse.rbg*halfLambert;
		//获取最终的光照，环境光+漫反射光照
		fixed3 color = ambient + diffuse;

		return fixed4(color, 1);
	}
		ENDCG
}
	}
	FallBack "Diffuse"
}
