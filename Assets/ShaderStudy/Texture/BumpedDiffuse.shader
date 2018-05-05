// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//完整的漫反射shader包括处理阴影，光照衰减，处理多个点光源等
Shader "Custom/BumpedDiffuse" {
	Properties {
		_Color("Color Tint",Color)=(1,1,1,1)
		_MainTex("Main Tex",2D)="white"{}
	    _BumpMap("NormalMap",2D)="bump"{}

	}
		SubShader{
			Tags{"RenderType" = "Opaque""Queue" = "Geometry"}//"Queue" = "Geometry"是默认的渲染队列

			Pass{//该Pass计算环境光以及自发光
			  Tags{"LightMode" = "ForwardBase"}

			  CGPROGRAM
			  #pragma multi_compile_fwbase
			  #pragma vertex vert
			  #pragma fragment frag

              #include "Lighting.cginc"
              #include "AutoLight.cginc"

			  fixed4 _Color;
	          sampler2D _MainTex;
			  float4 _MainTex_ST;
			  sampler2D _BumpMap;
			  float4 _BumpMap_ST;

			  struct a2v {
				  float4 vertex:POSITION;//顶点位置
				  float3 normal:NORMAL;//获取法线
				  float4 tangent:TANGENT;//获取切线
				  float4 texcoord:TEXCOORD0;//获取第一套纹理坐标
			  };
			  struct v2f {
				  float4 pos : SV_POSITION;
				  float4 uv:TEXCOORD0;//获取uv
				  float4 TtoW0:TEXCOORD1;
				  float4 TtoW1:TEXCOORD2;
				  float4 TtoW2:TEXCOORD3;
				  SHADOW_COORDS(4)//声明阴影纹理坐标，传入参数4表示将占用第5个差值寄存器TEXCOORD4
			  };
			  //在世界空间下计算光照模型
			  v2f vert(a2v v) {
				  v2f o;
				  o.pos = UnityObjectToClipPos(v.vertex);
				  o.uv.xy = v.texcoord*_MainTex_ST.xy + _MainTex_ST.zw;
				  o.uv.zw = v.texcoord*_BumpMap_ST.xy + _BumpMap_ST.zw;

				  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				  //cross(A,B)返回两个三元向量的叉积(cross product)。注意，输入参数必须是三元向量
				  fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

				  //切线空间转换到世界空间的变换矩阵，w分量储存世界空间的顶点坐标
				  o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				  o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				  o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				  TRANSFER_SHADOW(o);//计算阴影纹理坐标
				  return o;
			  }

			  fixed4 frag(v2f i) :SV_Target{
				  //取到世界空间的顶点坐标
				  float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				  float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				  float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				  fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				  //将法线从切线空间转换到世界空间，矩阵乘法
				  bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				  fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb*_Color.rgb;
				  //获得环境光部分
				  fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
				  //获得漫反射部分
				  fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(bump, lightDir));
				  //计算阴影
				  UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				  return fixed4(ambient + diffuse*atten, 1.0);
			  }

				  ENDCG
	}
		Pass{//该Pass不计算环境光以及自发光
			  Tags{"Lightmode" = "ForwardAdd"}
			  Blend One One

			  CGPROGRAM

			  #pragma multi_compile_fwadd
			  #pragma vertex vert
			  #pragma fragment frag

			  #include "Lighting.cginc"
			  #include "AutoLight.cginc"

			  fixed4 _Color;
			  sampler2D _MainTex;
			  float4 _MainTex_ST;
			  sampler2D _BumpMap;
			  float4 _BumpMap_ST;

			  struct a2v {
				  float4 vertex:POSITION;
				  float3 normal:NORMAL;
				  float4 tangent:TANGENT;//注意切线也是float4类型而不是float3类型
				  float4 texcoord:TEXCOORD0;
			  };
			  struct v2f {
				  float4 pos:SV_POSITION;
				  float4 uv:TEXCOORD0;
				  float4 TtoW0:TEXCOORD1;
				  float4 TtoW1:TEXCOORD2;
				  float4 TtoW2:TEXCOORD3;
				  SHADOW_COORDS(4)
			  };
			  
			  v2f vert(a2v v) {
				  v2f o;
				  o.pos = UnityObjectToClipPos(v.vertex);
				  o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				  o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				  float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				  fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				  fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				  fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

				  o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				  o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				  o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				  TRANSFER_SHADOW(o);
				  return o;
			  }
			  fixed4 frag(v2f i) :SV_Target{
				  float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				  fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				  fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				  bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				  fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb*_Color.rgb;

				  fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(bump, lightDir));

				  UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				  return fixed4(diffuse*atten, 1.0);
			  }
			ENDCG
         }
	}
	FallBack "Diffuse"
}
