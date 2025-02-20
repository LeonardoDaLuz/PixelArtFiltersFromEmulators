﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Pixel Art Filters/XBR-LV3"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1) //You should set this field in Unity scripting, material.SetColor
		_MainTex("Albedo (RGB)", 2D) = "white" {}
	decal("decal (RGB)", 2D) = "white" {} //you should also set this in scripting with material.SetTexture ("decal", yourDecalTexture)
	texture_size("texture_size", Vector) = (256,224,0,0)
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }

		///////////////////////////////////
		Pass
	{
		CGPROGRAM
		// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices ( THIS NOTE WAS MADE BY UNITY)
#pragma exclude_renderers gles // NOTE : this was added automatically by Unity each time I compile the shader ( THIS NOTE WAS MADE BY SONOSHEE)
#include "UnityCG.cginc"
#pragma vertex main_vertex
#pragma fragment main_fragment
#pragma target 3.0  

#include "compat_includes.inc"
		/*
		Hyllian's xBR-lv3 Shader

		Copyright (C) 2011-2015 Hyllian - sergiogdb@gmail.com

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in
		all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
		THE SOFTWARE.


		Incorporates some of the ideas from SABR shader. Thanks to Joshua Street.

		*/
		/*
		Leonardo da Luz Pinto's xBR-lv3 Adaptation to Unity ShaderLab

		Copyright (C) 2018 Leo Luz - leodluz@yahoo.com/leoluzprog@gmail.com

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in
		all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
		THE SOFTWARE.

		*/

#ifdef PARAMETER_UNIFORM
		uniform float XBR_Y_WEIGHT;
	uniform float XBR_EQ_THRESHOLD;
	uniform float XBR_EQ_THRESHOLD2;
	uniform float XBR_LV2_COEFFICIENT;
#else
#define XBR_Y_WEIGHT 48.0
#define XBR_EQ_THRESHOLD 10.0
#define XBR_EQ_THRESHOLD2 2.0
#define XBR_LV2_COEFFICIENT 2.0
#endif
		uniform COMPAT_Texture2D(decal) : TEXUNIT0;
	uniform float4x4 modelViewProj;
	uniform half4 _Color;

	const static float3x3 yuv = float3x3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
	const static float4 delta = float4(0.4, 0.4, 0.4, 0.4);


	float2 texture_size; // set from outside the shader ( THIS NOTE WAS MADE BY SONOSHEE)



	float4 df(float4 A, float4 B)
	{
		return float4(abs(A - B));
	}

	bool4 eq(float4 A, float4 B)
	{
		return (df(A, B) < XBR_EQ_THRESHOLD);
	}

	bool4 eq2(float4 A, float4 B)
	{
		return (df(A, B) < float4(2.0, 2.0, 2.0, 2.0));
	}


	float4 weighted_distance(float4 a, float4 b, float4 c, float4 d, float4 e, float4 f, float4 g, float4 h)
	{
		return (df(a, b) + df(a, c) + df(d, e) + df(d, f) + 4.0*df(g, h));
	}

	struct out_vertex
	{
		float4 position : POSITION;
		float4 color : COLOR;
		float2 texCoord : TEXCOORD0;
		float4 t1       : TEXCOORD1;
		float4 t2       : TEXCOORD2;
		float4 t3       : TEXCOORD3;
		float4 t4       : TEXCOORD4;
		float4 t5       : TEXCOORD5;
		float4 t6       : TEXCOORD6;
		float4 t7       : TEXCOORD7;
	};

	//VERTEX_SHADER
	out_vertex main_vertex(appdata_base v)
	{
		out_vertex OUT;

		OUT.position = UnityObjectToClipPos(v.vertex);
		OUT.color = _Color;

		float2 ps = float2(1.0 / texture_size.x, 1.0 / texture_size.y);
		float dx = ps.x;
		float dy = ps.y;

		// A1 B1 C1
		// A0 A B C C4
		// D0 D E F F4
		// G0 G H I I4
		// G5 H5 I5

		// This line fix a bug in ATI cards. ( THIS NOTE WAS MADE BY XBR AUTHOR)
		//float2 texCoord = texCoord1 + float2(0.0000001, 0.0000001);

		OUT.texCoord = v.texcoord+ +float2(0.0000001, 0.0000001);
		OUT.t1 = v.texcoord.xxxy + float4(-dx, 0, dx, -2.0*dy); // A1 B1 C1
		OUT.t2 = v.texcoord.xxxy + float4(-dx, 0, dx, -dy); // A B C
		OUT.t3 = v.texcoord.xxxy + float4(-dx, 0, dx, 0); // D E F
		OUT.t4 = v.texcoord.xxxy + float4(-dx, 0, dx, dy); // G H I
		OUT.t5 = v.texcoord.xxxy + float4(-dx, 0, dx, 2.0*dy); // G5 H5 I5
		OUT.t6 = v.texcoord.xyyy + float4(-2.0*dx, -dy, 0, dy); // A0 D0 G0
		OUT.t7 = v.texcoord.xyyy + float4(2.0*dx, -dy, 0, dy); // C4 F4 I4

		return OUT;
	}
#define FILTRO(PE, PI, PH, PF, PG, PC, PD, PB, PA, G5, C4, G0, C1, I4, I5, N15, N14, N11, F, H) \
	if ( PE!=PH && ((PH==PF && ( (PE!=PI && (PE!=PB || PE!=PD || PB==C1 && PD==G0 || PF!=PB && PF!=PC || PH!=PD && PH!=PG)) \
	   || (PE==PG && (PI==PH || PE==PD || PH!=PD)) \
	   || (PE==PC && (PI==PH || PE==PB || PF!=PB)) ))\
	   || (PE!=PF && (PE==PC && (PF!=PI && (PH==PI && PF!=PB || PE!=PI && PF==C4) || PE!=PI && PE==PG)))) ) \
                 {\
	                N11 = (N11+F)*0.5;\
        	        N14 = (N14+H)*0.5;\
                	N15 = F;\
                 }\
	else if (PE!=PH && PE!=PF && (PH!=PI && PE==PG && (PF==PI && PH!=PD || PE!=PI && PH==G5)))\
	{\
                N11 = (N11+H)*0.5;\
                N14 = N11;\
                N15 = H;\
	}\



	float c_df(float3 c1, float3 c2) {
		float3 df = abs(c1 - c2);
		return df.r + df.g + df.b;
	}
	//FRAGMENT SHADER
	half4 main_fragment(out_vertex VAR) : COLOR
	{

		bool4 edr, edr_left, edr_up, edr3_left, edr3_up, px; // px = pixel, edr = edge detection rule
	bool4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	bool4 interp_restriction_lv3_left, interp_restriction_lv3_up;
	bool4 nc, nc30, nc60, nc45, nc15, nc75; // new_color
	float4 fx, fx_left, fx_up, final_fx, fx3_left, fx3_up; // inequations of straight lines.
	float3 res1, res2, pix1, pix2;
	float blend1, blend2;

	float2 fp = frac(VAR.texCoord*texture_size);

	float3 A1 = COMPAT_SamplePoint(decal, VAR.t1.xw).rgb;
	float3 B1 = COMPAT_SamplePoint(decal, VAR.t1.yw).rgb;
	float3 C1 = COMPAT_SamplePoint(decal, VAR.t1.zw).rgb;

	float3 A = COMPAT_SamplePoint(decal, VAR.t2.xw).rgb;
	float3 B = COMPAT_SamplePoint(decal, VAR.t2.yw).rgb;
	float3 C = COMPAT_SamplePoint(decal, VAR.t2.zw).rgb;

	float3 D = COMPAT_SamplePoint(decal, VAR.t3.xw).rgb;
	float3 E = COMPAT_SamplePoint(decal, VAR.t3.yw).rgb;
	float3 F = COMPAT_SamplePoint(decal, VAR.t3.zw).rgb;

	float3 G = COMPAT_SamplePoint(decal, VAR.t4.xw).rgb;
	float3 H = COMPAT_SamplePoint(decal, VAR.t4.yw).rgb;
	float3 I = COMPAT_SamplePoint(decal, VAR.t4.zw).rgb;

	float3 G5 = COMPAT_SamplePoint(decal, VAR.t5.xw).rgb;
	float3 H5 = COMPAT_SamplePoint(decal, VAR.t5.yw).rgb;
	float3 I5 = COMPAT_SamplePoint(decal, VAR.t5.zw).rgb;

	float3 A0 = COMPAT_SamplePoint(decal, VAR.t6.xy).rgb;
	float3 D0 = COMPAT_SamplePoint(decal, VAR.t6.xz).rgb;
	float3 G0 = COMPAT_SamplePoint(decal, VAR.t6.xw).rgb;

	float3 C4 = COMPAT_SamplePoint(decal, VAR.t7.xy).rgb;
	float3 F4 = COMPAT_SamplePoint(decal, VAR.t7.xz).rgb;
	float3 I4 = COMPAT_SamplePoint(decal, VAR.t7.xw).rgb;

	float4 b = mul(float4x3(B, D, H, F), XBR_Y_WEIGHT*yuv[0]);
	float4 c = mul(float4x3(C, A, G, I), XBR_Y_WEIGHT*yuv[0]);
	float4 e = mul(float4x3(E, E, E, E), XBR_Y_WEIGHT*yuv[0]);
	float4 d = b.yzwx;
	float4 f = b.wxyz;
	float4 g = c.zwxy;
	float4 h = b.zwxy;
	float4 i = c.wxyz;

	float4 i4 = mul(float4x3(I4, C1, A0, G5), XBR_Y_WEIGHT*yuv[0]);
	float4 i5 = mul(float4x3(I5, C4, A1, G0), XBR_Y_WEIGHT*yuv[0]);
	float4 h5 = mul(float4x3(H5, F4, B1, D0), XBR_Y_WEIGHT*yuv[0]);
	float4 f4 = h5.yzwx;

	float4 c1 = i4.yzwx;
	float4 g0 = i5.wxyz;
	float4 b1 = h5.zwxy;
	float4 d0 = h5.wxyz;

	float4 Ao = float4(1.0, -1.0, -1.0, 1.0);
	float4 Bo = float4(1.0,  1.0, -1.0,-1.0);
	float4 Co = float4(1.5,  0.5, -0.5, 0.5);
	float4 Ax = float4(1.0, -1.0, -1.0, 1.0);
	float4 Bx = float4(0.5,  2.0, -0.5,-2.0);
	float4 Cx = float4(1.0,  1.0, -0.5, 0.0);
	float4 Ay = float4(1.0, -1.0, -1.0, 1.0);
	float4 By = float4(2.0,  0.5, -2.0,-0.5);
	float4 Cy = float4(2.0,  0.0, -1.0, 0.5);

	float4 Az = float4(6.0, -2.0, -6.0, 2.0);
	float4 Bz = float4(2.0, 6.0, -2.0, -6.0);
	float4 Cz = float4(5.0, 3.0, -3.0, -1.0);
	float4 Aw = float4(2.0, -6.0, -2.0, 6.0);
	float4 Bw = float4(6.0, 2.0, -6.0,-2.0);
	float4 Cw = float4(5.0, -1.0, -3.0, 3.0);

	// These inequations define the line below which interpolation occurs.
	fx = (Ao*fp.y + Bo*fp.x);
	fx_left = (Ax*fp.y + Bx*fp.x);
	fx_up = (Ay*fp.y + By*fp.x);
	fx3_left = (Az*fp.y + Bz*fp.x);
	fx3_up = (Aw*fp.y + Bw*fp.x);

	// It uses CORNER_C if none of the others are defined.
#ifdef CORNER_A
	interp_restriction_lv1 = ((e != f) && (e != h));
#elif CORNER_B
	interp_restriction_lv1 = ((e != f) && (e != h) && (!eq(f,b) && !eq(h,d) || eq(e,i) && !eq(f,i4) && !eq(h,i5) || eq(e,g) || eq(e,c)));
#elif CORNER_D
	interp_restriction_lv1 = ((e != f) && (e != h) && (!eq(f,b) && !eq(h,d) || eq(e,i) && !eq(f,i4) && !eq(h,i5) || eq(e,g) || eq(e,c)) && (f != f4 && f != i || h != h5 && h != i || h != g || f != c || eq(b,c1) && eq(d,g0)));
#else
	interp_restriction_lv1 = ((e != f) && (e != h) && (!eq(f,b) && !eq(f,c) || !eq(h,d) && !eq(h,g) || eq(e,i) && (!eq(f,f4) && !eq(f,i4) || !eq(h,h5) && !eq(h,i5)) || eq(e,g) || eq(e,c)));
#endif
	interp_restriction_lv2_left = ((e != g) && (d != g));
	interp_restriction_lv2_up = ((e != c) && (b != c));
	interp_restriction_lv3_left = (eq2(g,g0) && !eq2(d0,g0));
	interp_restriction_lv3_up = (eq2(c,c1) && !eq2(b1,c1));

	float4 fx45 = smoothstep(Co - delta, Co + delta, fx);
	float4 fx30 = smoothstep(Cx - delta, Cx + delta, fx_left);
	float4 fx60 = smoothstep(Cy - delta, Cy + delta, fx_up);
	float4 fx15 = smoothstep(Cz - delta, Cz + delta, fx3_left);
	float4 fx75 = smoothstep(Cw - delta, Cw + delta, fx3_up);


	edr = (weighted_distance(e, c, g, i, h5, f4, h, f) < weighted_distance(h, d, i5, f, i4, b, e, i)) && interp_restriction_lv1;
	edr_left = ((XBR_LV2_COEFFICIENT*df(f,g)) <= df(h,c)) && interp_restriction_lv2_left;
	edr_up = (df(f,g) >= (XBR_LV2_COEFFICIENT*df(h,c))) && interp_restriction_lv2_up;
	edr3_left = interp_restriction_lv3_left;
	edr3_up = interp_restriction_lv3_up;


	nc45 = (edr &&             bool4(fx45));
	nc30 = (edr && edr_left && bool4(fx30));
	nc60 = (edr && edr_up   && bool4(fx60));
	nc15 = (edr && edr_left && edr3_left && bool4(fx15));
	nc75 = (edr && edr_up   && edr3_up   && bool4(fx75));

	px = (df(e,f) <= df(e,h));

	nc = (nc75 || nc15 || nc30 || nc60 || nc45);

	float4 final45 = nc45*fx45;
	float4 final30 = nc30*fx30;
	float4 final60 = nc60*fx60;
	float4 final15 = nc15*fx15;
	float4 final75 = nc75*fx75;

	float4 maximo = max(max(max(final15, final75),max(final30, final60)), final45);

	if (nc.x) { pix1 = px.x ? F : H; blend1 = maximo.x; }
	else if (nc.y) { pix1 = px.y ? B : F; blend1 = maximo.y; }
	else if (nc.z) { pix1 = px.z ? D : B; blend1 = maximo.z; }
	else if (nc.w) { pix1 = px.w ? H : D; blend1 = maximo.w; }

	if (nc.w) { pix2 = px.w ? H : D; blend2 = maximo.w; }
	else if (nc.z) { pix2 = px.z ? D : B; blend2 = maximo.z; }
	else if (nc.y) { pix2 = px.y ? B : F; blend2 = maximo.y; }
	else if (nc.x) { pix2 = px.x ? F : H; blend2 = maximo.x; }

	res1 = lerp(E, pix1, blend1);
	res2 = lerp(E, pix2, blend2);

	float3 res = lerp(res1, res2, step(c_df(E, res1), c_df(E, res2)));

	return float4(res, 1.0);
	}

		ENDCG
	}
	}
		FallBack "Diffuse"
}