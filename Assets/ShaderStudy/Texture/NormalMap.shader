// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//切线空间计算光照模型的带有法线贴图的shader
Shader "Custom/NormalMap" {
	Properties {
		_Color("Color Tint",Color)=(1,1,1,1)
		_MainTex("Main Tex",2D)="white"{}//获取主纹理
	    _BumpMap("Normal Map",2D)="bump"{}//获取法线纹理
		_BumpScale("Bump Scale",Float) = 1.0//获取法线纹理的深度
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20


	}
		SubShader{
			Pass{
			   Tags {"LightMode" = "ForwardBase"}
			   CGPROGRAM

			   #pragma vertex vert
			   #pragma fragment frag
			   #include"Lighting.cginc"
		//定义所需的变量名
		fixed4 _Color;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		float _BumpScale;
		fixed4 _Specular;
		float _Gloss;

		//定义顶点着色器的输入结构
		struct a2v {
			float4 vertex:POSITION;
			float3 normal:NORMAL;
			float4 tangent:TANGENT;//把顶点的切线方向填充到tangent中，注意tangent的类型是float4
			float4 texcoord:TEXCOORD0;

		};
		//定义顶点着色器的输出结构
		struct v2f {
			float4 pos:SV_POSITION;
			float4 uv : TEXCOORD0;//获取uv
			float3 lightDir:TEXCOORD1;//获取光照方向
			float3 viewDir:TEXCOORD2;//获取视角方向
		};

		//处理光照以及视角方向转化到切线空间，传递到片元着色器中
		v2f vert(a2v v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord.xy*_MainTex_ST.xy + _MainTex_ST.zw;//将主纹理贴图转化后存储到o.uv.xy中
			o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy + _BumpMap_ST.zw;//将法线纹理贴图转化后储存到o.uv.zw中

			TANGENT_SPACE_ROTATION;//获取切线空间的变换矩阵,包含了对v.normal以及v.tangent的处理
			//获取切线空间的光照方向，ObjSpaceLightDir()输入模型空间的顶点位置，返回模型空间的光照方向
			o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
			//获取切线空间的视角方向，ObjSpaceViewDir()输入模型空间的顶点位置，返回模型空间的视角方向
			o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
			return o;
		}
		//片元着色器
		fixed4 frag(v2f i) :SV_Target{
			//归一化处理
			fixed3 tangentLightDir = normalize(i.lightDir);
		    fixed3 tangentViewDir = normalize(i.viewDir);

			//对纹理进行采样，返回纹素值(这一部分没有很理解)
			fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
			fixed3 tangentNormal;
			tangentNormal = UnpackNormal(packedNormal);//将法线信息反映射回来
			tangentNormal.xy *= _BumpScale;//乘上缩放
			tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));//法线的z分量可以由xy的分量求得
			//-----------------------


			//计算光照
			//获得材质的漫反射属性
			fixed3 albedo = tex2D(_MainTex, i.uv).rgb*_Color.rgb;
			//获得材质的环境光部分
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
			//半兰伯特模型
			fixed3 halfLambert = dot(tangentNormal, tangentLightDir)*0.5 + 0.5;
			//获得漫反射光照部分
			fixed3 diffuse = _LightColor0.rgb*albedo*halfLambert;
			//获得高光部分,(视角方向+光照方向)再做归一化
			fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(tangentNormal, halfDir)), _Gloss);//高光模型
			
			return fixed4(ambient + diffuse + specular, 1.0);
		}
			ENDCG

}

	}
	FallBack "Specular"
}
