﻿//Copyright(c) <2019> <JackyGun twitter@konchannyan>
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions :
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Shader "JackyGun/LeadShader/chainMesh"
{
	Properties
	{
		_Tess("Tess",Range(1, 32)) = 4
		_TargetId("TargetId",Float) = 1.5
		_DomainId("DomainId",Float) = 1.0
		_ChainLen("ChainLen",Float) = 1.0
		_MaxDis("MaxDis",Float) = 5.0
		_CanDebug("CanDebug",Float) = 0.0
		_Color0("Color0", Color) = (0, 0, 0, 1)
		_Color1("Color1", Color) = (1, 1, 1, 1)
	}

		SubShader
	{
		Tags{ "Queue" = "AlphaTest+2" "RenderType" = "Opaque" }

		Pass
	{
		CGPROGRAM
#pragma target 5.0
#pragma vertex mainVS
#pragma hull mainHS
#pragma domain mainDS
#pragma geometry mainGS
#pragma fragment mainFS
#pragma multi_compile_instancing

#include "UnityCG.cginc"

	int _Tess;
	float _TargetId;
	float _DomainId;
	float _ChainLen;
	float _MaxDis;
	float _CanDebug;
	float4 _Color0;
	float4 _Color1;

	// Structure
	struct VS_IN
	{
		float4 pos   : POSITION;
		uint instanceID : SV_InstanceID;
	};

	struct VS_OUT
	{
		float4 pos    : POSITION;
		uint instanceID : INSTANCE_ID;
		int targetID : TARGET_ID;
	};

	struct CONSTANT_HS_OUT
	{
		float Edges[4] : SV_TessFactor;
		float Inside[2] : SV_InsideTessFactor;
	};

	struct HS_OUT
	{
		uint instanceID : INSTANCE_ID;
		int targetID : TARGET_ID;
	};

	struct DS_OUT
	{
		uint pid : PID;	// GeometryShaderに実行用の一意連続なIDを発行する
		uint instanceID : INSTANCE_ID;
		int targetID : TARGET_ID;
	};

	struct GS_OUT
	{
		int state : STATE;
		float4 vertex : SV_POSITION;
		float4 color : COLOR0;
	};

	// Main
	VS_OUT mainVS(VS_IN In)
	{
#if defined(UNITY_INSTANCING_ENABLED)

		VS_IN dm;

		uint iid = In.instanceID;

		uint i;
		int tid = -1;
		for (i = 1; i < 8; i++)
		{
			if (i == iid) continue;

			dm.instanceID = i;
			UNITY_SETUP_INSTANCE_ID(dm);
			float sX = sqrt(pow(unity_ObjectToWorld[0].x, 2) + pow(unity_ObjectToWorld[0].y, 2) + pow(unity_ObjectToWorld[0].z, 2));

			if (distance(sX, _TargetId) < _DomainId) {
				tid = i;
				break;
			}
		}

		VS_OUT Out;
		Out.pos = In.pos;
		Out.instanceID = In.instanceID;
		Out.targetID = tid;
		
		return Out;
#else
		VS_OUT Out;
		Out.pos = In.pos;
		Out.instanceID = In.instanceID;
		Out.targetID = -2;
		return Out;
#endif
	}

	CONSTANT_HS_OUT mainCHS()
	{
		CONSTANT_HS_OUT Out;

		int t = _Tess + 1;
		Out.Edges[0] = t;
		Out.Edges[1] = t;
		Out.Edges[2] = t;
		Out.Edges[3] = t;
		Out.Inside[0] = t;
		Out.Inside[1] = t;

		return Out;
	}

	[domain("quad")]
	[partitioning("pow2")]
	[outputtopology("point")]
	[outputcontrolpoints(4)]
	[patchconstantfunc("mainCHS")]
	HS_OUT mainHS(InputPatch<VS_OUT, 4> In, uint i : SV_OutputControlPointID)
	{
		HS_OUT Out;
		Out.instanceID = In[0].instanceID;
		Out.targetID = In[0].targetID;
		return Out;
	}

	[domain("quad")]
	DS_OUT mainDS(CONSTANT_HS_OUT In, const OutputPatch<HS_OUT, 4> patch, float2 uv : SV_DomainLocation)
	{
		DS_OUT Out;
		Out.pid = (uint)(uv.x * _Tess) + ((uint)(uv.y * _Tess) * _Tess);
		Out.instanceID = patch[0].instanceID;
		Out.targetID = patch[0].targetID;
		return Out;
	}

	[maxvertexcount(36)]
	void mainGS(point DS_OUT input[1], inout TriangleStream<GS_OUT> outStream)
	{
		GS_OUT o;

		uint pid = input[0].pid;
		uint iid = input[0].instanceID;
		int tid = input[0].targetID;

		if (tid < 0) {
			if (pid == 0 && _CanDebug > 0) {
				o.state = tid;
				o.color = 0;
				o.vertex = UnityObjectToClipPos(float4(-0.01, -0.01, 0, 1));
				outStream.Append(o);
				o.vertex = UnityObjectToClipPos(float4(-0.01, +0.01, 0, 1));
				outStream.Append(o);
				o.vertex = UnityObjectToClipPos(float4(+0.01, -0.01, 0, 1));
				outStream.Append(o);
				outStream.RestartStrip();
				o.vertex = UnityObjectToClipPos(float4(-0.01, +0.01, 0, 1));
				outStream.Append(o);
				o.vertex = UnityObjectToClipPos(float4(+0.01, +0.01, 0, 1));
				outStream.Append(o);
				o.vertex = UnityObjectToClipPos(float4(+0.01, -0.01, 0, 1));
				outStream.Append(o);
				outStream.RestartStrip();
			}
			return;
		}

		DS_OUT dm;

		dm.instanceID = tid;
		UNITY_SETUP_INSTANCE_ID(dm);
		float4 ppos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

		dm.instanceID = iid;
		UNITY_SETUP_INSTANCE_ID(dm);
		float4 mpos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

		if (distance(ppos, mpos) > _MaxDis)
			return;

		float len = _ChainLen;
	//	float y0 = mpos.y;
	//	float y1 = ppos.y;
		float y0 = min(mpos.y, ppos.y);
		float y1 = max(mpos.y, ppos.y);
		float w = distance(mpos.xz, ppos.xz);
		float b = y0 + y1;
		float c = 0.25f * (b * b + w * w - len * len);
		float d = b * b - 4 * 1 * c;
		float y = y0;
	//	float y = min(y0, y1);
		if (d >= 0) {
			y = 0.25f * ( - b - sqrt(d));
		}

		//float h0 = (y0 - y);
		//float h1 = (y1 - y);

		//float xa0 = -sqrt(h0);
		//float xa1 = +sqrt(h1);

		y = lerp(y1, y, 1);
		float h = (y1 - y);
		float w2 = w / 2;
		w2 = w2 * w2;
		w2 = max(w2, 0.000001f);
		float aa = h / w2;

		float t_size = (_Tess + 1) * _Tess + 1;
		float e0 = (pid + 0) / t_size;
		float e1 = (pid + 1) / t_size;

		float x0 = e0 * 2 - 1;
		float x1 = e1 * 2 - 1;
		x0 *= w / 2;
		x1 *= w / 2;
		float ye0 = aa * x0 * x0 - h;
		float ye1 = aa * x1 * x1 - h;

		float3 fpos = lerp(mpos.xyz, ppos.xyz, e0) + float3(0, ye0, 0);
		float3 tpos = lerp(mpos.xyz, ppos.xyz, e1) + float3(0, ye1, 0);

		//float xi0 = lerp(xa0,xa1,e0);
		//float xi1 = lerp(xa0,xa1,e1);
		//float ye0 = xi0 * xi0 + y;
		//float ye1 = xi1 * xi1 + y;

		//mpos.y = 0;
		//ppos.y = 0;

		//float3 fpos = lerp(mpos.xyz, ppos.xyz, e0) + float3(0, ye0, 0);
		//float3 tpos = lerp(mpos.xyz, ppos.xyz, e1) + float3(0, ye1, 0);

		float3 dd = tpos - fpos;

		fpos += dd * 0.25f;
		tpos -= dd * 0.25f;

		float3 cdir = 0.005;

		float4 wpos0 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, +cdir.z), 1));
		float4 wpos1 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, +cdir.z), 1));
		float4 wpos2 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, -cdir.z), 1));
		float4 wpos3 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, -cdir.z), 1));
		float4 wpos4 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, +cdir.z), 1));
		float4 wpos5 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, +cdir.z), 1));
		float4 wpos6 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, -cdir.z), 1));
		float4 wpos7 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, -cdir.z), 1));
		
		o.state = tid;
		o.color = pid % 2 ? _Color0 : _Color1;

		o.vertex = wpos0;
		outStream.Append(o);
		o.vertex = wpos1;
		outStream.Append(o);
		o.vertex = wpos2;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos2;
		outStream.Append(o);
		o.vertex = wpos1;
		outStream.Append(o);
		o.vertex = wpos3;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos4;
		outStream.Append(o);
		o.vertex = wpos6;
		outStream.Append(o);
		o.vertex = wpos5;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos6;
		outStream.Append(o);
		o.vertex = wpos7;
		outStream.Append(o);
		o.vertex = wpos5;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos0;
		outStream.Append(o);
		o.vertex = wpos2;
		outStream.Append(o);
		o.vertex = wpos4;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos4;
		outStream.Append(o);
		o.vertex = wpos2;
		outStream.Append(o);
		o.vertex = wpos6;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos3;
		outStream.Append(o);
		o.vertex = wpos1;
		outStream.Append(o);
		o.vertex = wpos7;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos7;
		outStream.Append(o);
		o.vertex = wpos1;
		outStream.Append(o);
		o.vertex = wpos5;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos1;
		outStream.Append(o);
		o.vertex = wpos0;
		outStream.Append(o);
		o.vertex = wpos5;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos5;
		outStream.Append(o);
		o.vertex = wpos0;
		outStream.Append(o);
		o.vertex = wpos4;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos2;
		outStream.Append(o);
		o.vertex = wpos3;
		outStream.Append(o);
		o.vertex = wpos6;
		outStream.Append(o);
		outStream.RestartStrip();

		o.vertex = wpos6;
		outStream.Append(o);
		o.vertex = wpos3;
		outStream.Append(o);
		o.vertex = wpos7;
		outStream.Append(o);
		outStream.RestartStrip();
	}

	float4 mainFS(GS_OUT i) : SV_Target
	{
		if (i.state < 0){
			// black : error
			// white : not hit
			return float4((i.state + 2).rrr, 1);
		}

		return i.color;
	}
		ENDCG
	}
	}
}
