//Copyright(c) <2019> <JackyGun:twitter@konchannyan>
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions :
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Shader "JackyGun/LeadShader/beacon"
{
	Properties
	{
	}

		SubShader
	{
		Tags{ "Queue" = "AlphaTest+1" "RenderType" = "Opaque" }

		Pass
	{
		CGPROGRAM
#pragma target 5.0
#pragma vertex mainVS
#pragma fragment mainFS
#pragma multi_compile_instancing

#include "UnityCG.cginc"

	// Structure
	struct VS_IN
	{
	};

	struct VS_OUT
	{
    bool _ : TO_CREATE_CBUFFER;
};

	// Main
	VS_OUT mainVS(VS_IN In)
	{
        VS_OUT o;
        o._ = unity_ObjectToWorld;
    return o;
}


	float4 mainFS(VS_OUT i) : SV_Target
	{
		return 0;
	}
		ENDCG
	}
	}
}
