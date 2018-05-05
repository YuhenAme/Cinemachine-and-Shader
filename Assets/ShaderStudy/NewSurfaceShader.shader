// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/NewSurfaceShader" {
	Properties{
		_Color("Color Tint", Color) = (1.0,1.0,1.0,1.0)
	}
	SubShader{
		Pass{
		   CGPROGRAM

		   #pragma vertex vert
		   #pragma fragment frag
			   
		   fixed4 _Color;
	//定义定点着色器的输入结构体
	struct a2v {
		float4 vertex : POSITION;//获取模型空间各定点的位置
		float4 normal : NORMAL;//获取法线
		float4 texcoord : TEXCOORD0;//获取第一套纹理
			   };
	//定义片元着色器的输入结构体
	struct v2f {
		float4 pos : SV_POSITION;//裁剪空间的定点坐标
		fixed3 color : COLOR0;
	};

	//定点着色器函数，会返回一个v2f类型的值
	v2f vert(a2v v) {
		v2f o;
		//将模型空间的各个定点的坐标转换到裁剪空间，UNITY_MATRIX_MVP是从模型空间到裁剪空间的变换矩阵
		o.pos = UnityObjectToClipPos(v.vertex);
		//v.normal包含顶点的法线方向
		//将分量范围映射到0到1
		o.color = v.normal*0.5 + fixed3(0.5, 0.5, 0.5);
		return o;
	}
	fixed4 frag(v2f i) : SV_Target{
		fixed3 c = i.color;
		c *= _Color.rbg;
		return fixed4(c, 1.0);
	
	}
		ENDCG
		}
		
	}
	FallBack "Diffuse"
}
