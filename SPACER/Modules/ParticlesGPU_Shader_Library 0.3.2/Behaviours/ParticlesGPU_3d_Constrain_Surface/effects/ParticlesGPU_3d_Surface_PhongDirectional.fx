//@author: dottore
//@description: Draws a surface using the data position texture. shading by phong directional
//@tags: 3d surface
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWV: WORLDVIEW ;

#include "PhongDirectional.fxh"

//position texture
texture Tex <string uiname="Data Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

//normal texture
texture Tex2 <string uiname="Normal Texture";>;
sampler SampNorm = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = Clamp;
    AddressV = Clamp;
};


float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

// --------------------------------------------------------------------------------------------------
// STRUCT:
// --------------------------------------------------------------------------------------------------

struct vs2ps
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD3 ;

};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS:
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    TexCd = mul(TexCd, tTex);

    float4 particleData = tex2Dlod(Samp, TexCd);   //position data per vertices
    float3 NormO = tex2Dlod(SampNorm, TexCd); // normals from Normal texture;
    
    PosO.xyz = particleData.xyz;

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    Out.ViewDirV = -normalize(mul(PosO, tWV));

    //then apply the tVP
    Out.PosWVP = mul(PosO, tVP);
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
    float4 col = PhongDirectional(In.NormV, In.ViewDirV, In.LightDirV);
    return col ;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Surface_PhongDirectional
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
