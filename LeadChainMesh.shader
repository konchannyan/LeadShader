//Copyright(c) <2019> <JackyGun twitter@konchannyan>
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
		[Toggle(CAN_DEBUG)]_CanDebug("CanDebug",Float) = 0.0
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
#pragma shader_feature CAN_DEBUG
#define UNITY_INSTANCING_ENABLED//unity_InstancingIDを使えるようにする
#include "UnityCG.cginc"

	int _Tess;
	float _TargetId;
	float _DomainId;
	float _ChainLen;
	float _MaxDis;
	fixed4 _Color0;
	fixed4 _Color1;

	// Structure
	struct VS_IN
	{
		float4 pos   : POSITION;
		uint instanceID : SV_InstanceID;
	};

	struct VS_OUT
	{
		float4 pos    : POSITION;
		int targetID : TARGET_ID;
	};

	struct CONSTANT_HS_OUT
	{
		float Edges[4] : SV_TessFactor;
		float Inside[2] : SV_InsideTessFactor;
	};

	struct HS_OUT
	{
		int targetID : TARGET_ID;
	};

	struct DS_OUT
	{
		uint pid : PID;	// GeometryShaderに実行用の一意連続なIDを発行する
		int targetID : TARGET_ID;
	};
    struct GS_IN
    {
        uint pid : PID; // GeometryShaderに実行用の一意連続なIDを発行する
        uint instanceID : SV_InstanceID;
        int targetID : TARGET_ID;
    };
	struct GS_OUT
	{
		float4 vertex : SV_POSITION;
		fixed4 color : COLOR0;
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

            unity_InstanceID = i;
            float sX = length(unity_ObjectToWorld[0].xyz);
			if (distance(sX, _TargetId) < _DomainId) {
				tid = i;
				break;
			}
		}

		VS_OUT Out;
		Out.pos = In.pos;
		Out.targetID = tid;
		
		return Out;
#else
		VS_OUT Out;
		Out.pos = In.pos;
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
		Out.targetID = In[0].targetID;
		return Out;
	}

	[domain("quad")]
	DS_OUT mainDS(CONSTANT_HS_OUT In, const OutputPatch<HS_OUT, 4> patch, float2 uv : SV_DomainLocation)
	{
		DS_OUT Out;
		Out.pid = (uint)(uv.x * _Tess) + ((uint)(uv.y * _Tess) * _Tess);
		Out.targetID = patch[0].targetID;
		return Out;
	}
	[maxvertexcount(36)]
	void mainGS(point GS_IN input[1], inout TriangleStream<GS_OUT> outStream)
	{
		

		uint pid = input[0].pid;
		uint iid = input[0].instanceID;
		int tid = input[0].targetID;

		if (tid < 0) {
        #if CAN_DEBUG
			if (pid == 0) {
                GS_OUT o;
                o.color = 
                // black : error
	            // white : not hit
                fixed4((tid + 2).rrr, 1);
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
#endif
			return;
		}

		DS_OUT dm;

        unity_InstanceID = tid;
		//float4 ppos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
        float3 ppos = unity_ObjectToWorld._14_24_34;

        unity_InstanceID = iid;
		//float4 mpos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
    float3 mpos = unity_ObjectToWorld._14_24_34;

        
		if (distance(ppos, mpos) > _MaxDis)
			return;

		//float len = _ChainLen;
        float lenPow2 = _ChainLen*_ChainLen;
	//	float y0 = mpos.y;
	//	float y1 = ppos.y;
		float y0 = min(mpos.y, ppos.y);
		float y1 = max(mpos.y, ppos.y);
		float w = distance(mpos.xz, ppos.xz);
		float b = y0 + y1;
		//float c = 0.25f * (b * b + w * w - len * len);
    float cX4 = mad(b, b, mad(w, w, -lenPow2));
		//float d = b * b - 4 * 1 * c;
    float d = mad(b, b, -cX4);
		float y = y0;
	//	float y = min(y0, y1);
		//if (d >= 0) {
        y = d >= 0 ? 0.25f * (-b - sqrt(d)) : y;
    //}

		//float h0 = (y0 - y);
		//float h1 = (y1 - y);

		//float xa0 = -sqrt(h0);
		//float xa1 = +sqrt(h1);

		//y = lerp(y1, y, 1);
		float h = (y1 - y);
		float w2 = w / 2;
    //float t_size = (_Tess + 1) * _Tess + 1;
    float t_sizeRCP = rcp(mad(_Tess + 1, _Tess, 1));
		//float e0 = (input[0].pid + 0) / t_size;
    float e0 = pid * t_sizeRCP;
		//float e1 = (input[0].pid + 1) / t_size;
    float e1 = e0 + t_sizeRCP;//e0がない場合でもmadで1OPで求まる


    //float x0 = (e0 * 2 - 1) * (w / 2);
    float x0 = mad(e0, w, -w2);
    //float x1 = (e1 * 2 - 1) * (w / 2);

    float x1 = mad(e0, w, -w2);

    
    
    //ここまでw2=w/2
		w2 = w2 * w2;
		w2 = max(w2, 0.000001f);
		float aa = h / w2;

		

		
		
		float ye0 = aa * x0 * x0 - h;
		float ye1 = aa * x1 * x1 - h;

    float3 fpos = lerp(mpos.xyz, ppos.xyz, e0);//+float3(0, ye0, 0);
    fpos.y += ye0;
    float3 tpos = lerp(mpos.xyz, ppos.xyz, e1); // + float3(0, ye1, 0);
    tpos.y += ye1;

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
		//tpos -= dd * 0.25f;//notUsed


    

    //o.state = tid;
		//o.color = pid % 2 ? _Color0 : _Color1;
    //float4 color;
    
        fixed4 color = pid & 1 ? _Color0 : _Color1;
        
        static const float3 cdir = 0.005;//これ暗黙的に何に変換されてる？<= float3(0.005,0.005,0.005)でした
		//float4 wpos0 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, +cdir.z), 1));
		//float4 wpos1 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, +cdir.z), 1));
		//float4 wpos2 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, -cdir.z), 1));
		//float4 wpos3 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, -cdir.z), 1));
		//float4 wpos4 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, +cdir.z), 1));
		//float4 wpos5 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, +cdir.z), 1));
		//float4 wpos6 = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, -cdir.z), 1));
		//float4 wpos7 = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, -cdir.z), 1));
        GS_OUT outs[8];
        outs[0].color = color;
        outs[1].color = color;
        outs[2].color = color;
        outs[3].color = color;
        outs[4].color = color;
        outs[5].color = color;
        outs[6].color = color;
        outs[7].color = color;
        outs[0].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, +cdir.z), 1));    
        outs[1].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, +cdir.z), 1));  
        outs[2].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, +cdir.y, -cdir.z), 1));   
        outs[3].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, +cdir.y, -cdir.z), 1));    
        outs[4].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, +cdir.z), 1));    
        outs[5].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, +cdir.z), 1));    
        outs[6].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(-cdir.x, -cdir.y, -cdir.z), 1));    
        outs[7].vertex = mul(UNITY_MATRIX_VP, float4(fpos + float3(+cdir.x, -cdir.y, -cdir.z), 1));


        outStream.Append(outs[0]);    
        outStream.Append(outs[1]);    
        outStream.Append(outs[2]);
        outStream.RestartStrip();
    
        outStream.Append(outs[2]);    
        outStream.Append(outs[1]);    
        outStream.Append(outs[3]);
        outStream.RestartStrip();
    
        outStream.Append(outs[4]);    
        outStream.Append(outs[6]);    
        outStream.Append(outs[5]);
        outStream.RestartStrip();
    
        outStream.Append(outs[6]);    
        outStream.Append(outs[7]);    
        outStream.Append(outs[5]);
        outStream.RestartStrip();
    
        outStream.Append(outs[0]);    
        outStream.Append(outs[2]);
        outStream.Append(outs[4]);
        outStream.RestartStrip();
    
        outStream.Append(outs[4]);    
        outStream.Append(outs[2]);   
        outStream.Append(outs[6]);
        outStream.RestartStrip();
    
        outStream.Append(outs[3]);   
        outStream.Append(outs[1]);    
        outStream.Append(outs[7]);
        outStream.RestartStrip();
  
        outStream.Append(outs[7]);    
        outStream.Append(outs[1]);    
        outStream.Append(outs[5]);
        outStream.RestartStrip();
    
        outStream.Append(outs[1]);   
        outStream.Append(outs[0]);   
        outStream.Append(outs[5]);
        outStream.RestartStrip();
    
        outStream.Append(outs[5]);   
        outStream.Append(outs[0]);   
        outStream.Append(outs[4]);
        outStream.RestartStrip();
    
        outStream.Append(outs[2]);   
        outStream.Append(outs[3]);   
        outStream.Append(outs[6]);
        outStream.RestartStrip();

        outStream.Append(outs[6]);
        outStream.Append(outs[3]);
        outStream.Append(outs[7]);
        outStream.RestartStrip();
    }

	fixed4 mainFS(GS_OUT i) : SV_Target
	{
        return i.color;
    }
		ENDCG
	}
	}
}
