//@author: tonfilm, dottore
//@description: bicubic interpolation of the incoming texture; outputs position and normals
//@tags: bicubic resample MRT
//@credits: 

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex <string uiname="Texture";>;

//samplers
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    addressU = clamp;
    addressV = clamp;

};

//only for the neares neighbour ps
sampler SampPoint = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = point;         //sampler states
    MinFilter = point;
    MagFilter = point;
    addressU = clamp;
    addressV = clamp;

};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

float2 sampleCoords1 ;
float2 sampleCoords2 ;
float2 sampleCoords3 ;
//alpha
float Alpha <float uimin=0.0; float uimax=1.0;> = 1;

//include the bicubic texture lookup
#include "Bicubic2.fxh"

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0
    )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(PosO, tWVP);

    //transform texturecoordinates
    Out.TexCd = mul(TexCd, tTex);
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

struct MRT
{
    float4 c1 : COLOR ;
    float4 c2 : COLOR1 ;
};

MRT PSbic(vs2ps In)
{     
    MRT c;
    // Position
    c.c1 = tex2Dbicubic(Samp, In.TexCd);
    // Normals
    float3 sample1 = tex2Dbicubic(Samp, float2( In.TexCd + sampleCoords1 ));
    float3 sample2 = tex2Dbicubic(Samp, float2( In.TexCd + sampleCoords2 ));
    float3 sample3 = tex2Dbicubic(Samp, float2( In.TexCd + sampleCoords3 ));

    float3 tang = sample2 - sample1;
    float3 bitang = sample3 - sample1; 
    
    c.c2 = float4(normalize(cross(tang, bitang)) , 1);

    return c;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


// PS Bilinear
MRT PSlin(vs2ps In)
{     
    MRT c;
    // Position
    c.c1 = tex2D(Samp, In.TexCd);
    // Normals
    float3 sample1 = tex2D(Samp, float2( In.TexCd + sampleCoords1 ));
    float3 sample2 = tex2D(Samp, float2( In.TexCd + sampleCoords2 ));
    float3 sample3 = tex2D(Samp, float2( In.TexCd + sampleCoords3 ));

    float3 tang = sample2 - sample1;
    float3 bitang = sample3 - sample1; 
    
    c.c2 = float4(normalize(cross(tang, bitang)) , 1);

    return c;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// PS Nearest Neighbour
MRT PSnn(vs2ps In)
{     
    MRT c;
    // Position
    c.c1 = tex2D(SampPoint, In.TexCd); 
    // Normals
    float3 sample1 = tex2D(SampPoint, float2( In.TexCd + sampleCoords1 ));
    float3 sample2 = tex2D(SampPoint, float2( In.TexCd + sampleCoords2 ));
    float3 sample3 = tex2D(SampPoint, float2( In.TexCd + sampleCoords3 ));

    float3 tang = sample2 - sample1;
    float3 bitang = sample3 - sample1; 
    
    c.c2 = float4(normalize(cross(tang, bitang)) , 1);

    return c;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

technique Bicubic
{
    pass p0
    {
        AlphaBlendEnable = false;
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PSbic();
    }
}

technique Bilinear
{
    pass p0
    {
        AlphaBlendEnable = false;
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PSlin();
    }
}

technique NearestNeighbour
{
    pass p0
    {
        AlphaBlendEnable = false;
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PSnn();
    }
}
