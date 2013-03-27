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

#include "Phong_Directional-Point.fxh"

//position texture
texture Tex <string uiname="XY Resampled Texture";>;
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
texture Tex2 <string uiname="Normals Texture";>;
sampler SampNorm = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

//position texture
texture TexImage <string uiname="Image Texture";>;
sampler SampImage = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexImage);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float4 cAmb : COLOR <String uiname="Color";>  = {1, 1, 1, 1};

//##############################################################################
// CONSTANT ####################################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------
struct vs2ps0
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
    float3 camera_position : TEXCOORD0 ;
    float2 texCdImage: TEXCOORD1 ;
};
// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

vs2ps0 VS0(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float2 TexCd2: TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    vs2ps0 Out = (vs2ps0)0;

    float4 particleData = tex2Dlod(Samp, TexCd);   //position data per vertices
    float3 NormO = tex2Dlod(SampNorm, TexCd); // normals from Normal texture;
    
    PosO.xyz = particleData.xyz;

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //then apply the tVP
    Out.PosWVP = mul(PosO, tVP);
    
    Out.camera_position = mul(PosO, tWV);
    
    Out.texCdImage = TexCd2;
    
    return Out;
}


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS0(vs2ps0 In): COLOR
{
    return cAmb * tex2D(SampImage,In.texCdImage);
}

//##############################################################################
// PHONG DIRECTIONAL ###########################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------
struct vs2ps1
{
    float4 PosWVP: POSITION ;
    float3 NormV: NORMAL ;
    float3 camera_position : TEXCOORD3 ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD2 ;
    float2 texCdImage: TEXCOORD4 ;
};
// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

vs2ps1 VS1(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float2 TexCd2: TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    vs2ps1 Out = (vs2ps1)0;

    Out.TexCd = mul(TexCd, tTex);

    float4 particleData = tex2Dlod(Samp, Out.TexCd);   //position data per vertices
    float3 NormO = tex2Dlod(SampNorm, Out.TexCd); // normals from Normal texture;
    
    PosO.xyz = particleData.xyz;

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    Out.ViewDirV = -normalize(mul(PosO, tWV));

    //then apply the tVP
    Out.PosWVP = mul(PosO, tVP);
    
    Out.camera_position = mul(PosO, tWV);
    Out.texCdImage = TexCd2;
    
    return Out;
}


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS1(vs2ps1 In): COLOR
{
 return PhongDirectional(In.NormV, In.ViewDirV, In.LightDirV)*tex2D(SampImage,In.texCdImage);
}

//##############################################################################
// PHONG POINT #################################################################
//##############################################################################

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------

struct vs2ps2
{
    float4 PosWVP: POSITION ;
    float4 PosW: TEXCOORD2 ;
    float3 NormV: NORMAL ;
    float3 camera_position : TEXCOORD4 ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 ViewDirV: TEXCOORD3 ;
    float2 texCdImage: TEXCOORD5 ;
};

// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

// PLACE and DEFORM technique
vs2ps2 VS2(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float2 TexCd2: TEXCOORD1 )
{
    //inititalize all fields of output struct with 0
    vs2ps2 Out = (vs2ps2)0;

    Out.TexCd = mul(TexCd, tTex);

    float4 particleData = tex2Dlod(Samp, Out.TexCd);   //position data per vertices
    float3 NormO = tex2Dlod(SampNorm, Out.TexCd); // normals from Normal texture;
    
    Out.PosW = float4(particleData.xyz,1);

    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);

    //inverse light direction in view space
    Out.LightDirV = mul(LightDirW, tV);
    Out.ViewDirV = -normalize(mul(Out.PosW, tWV));

    //then apply the tVP
    Out.PosWVP = mul(Out.PosW, tVP);
    
    Out.camera_position = mul(Out.PosW, tWV);
    Out.texCdImage = TexCd2;
    
    return Out;
}

// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

float4 PS2(vs2ps2 In): COLOR
{
    return PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV)*tex2D(SampImage,In.texCdImage);
}

// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------

technique Constant
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS0();
        PixelShader  = compile ps_3_0 PS0();
    }
}

technique Phong_Directional
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS1();
        PixelShader  = compile ps_3_0 PS1();
    }
}

technique Phong_Point
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS2();
        PixelShader  = compile ps_3_0 PS2();
    }
}




