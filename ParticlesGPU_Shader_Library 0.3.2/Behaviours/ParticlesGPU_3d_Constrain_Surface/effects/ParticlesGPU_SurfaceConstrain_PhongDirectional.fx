//@author: dottore
//@description: Places GPUparticles onto a GPU surface. shading: phong directional
//@tags: 3d surface constrain particles
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
texture Tex <string uiname="Surface Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = mirror;
    AddressV = mirror;
};

//normal texture
texture Tex2 <string uiname="Surface Normal Texture";>;
sampler SampNorm = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex2);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    AddressU = mirror;
    AddressV = mirror;
};

//Placing texture
texture Tex3 <string uiname="Placing Texture";>;
sampler SampPlace = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex3);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

// --------------------------------------------------------------------------------------------------
// --------FUNCTIONS---------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------

#define minTwoPi -6.283185307179586476925286766559
#define TwoPi 6.283185307179586476925286766559

//rotate point by quaternion

float3 rotPbyQ (float3 p, float4 q){

   return  p*(q.x*q.x - q.y*q.y - q.z*q.z - q.w*q.w) +
         2*q.yzw*dot(q.yzw, p) + 2*cross(p, q.yzw)*q.x;

}

//rotate point by euler angles

float3 rotate(float3 pointPos, float pitch, float yaw, float roll)
{

  pitch *= minTwoPi;
  yaw    = (yaw+0.25) * minTwoPi;
  roll  *= minTwoPi;

  pointPos.xyz = float3(pointPos.y, pointPos.z, pointPos.x);

  float4 es;
  float coy = cos(yaw*0.5);
  float siy = sin(yaw*0.5);

  es.x = cos(0.5*(roll+pitch))*coy;
  es.y = sin(0.5*(roll-pitch))*siy;
  es.z = cos(0.5*(roll-pitch))*siy;
  es.w = sin(0.5*(roll+pitch))*coy;

  return rotPbyQ(pointPos, es);
}

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

// PLACE technique
vs2ps VS(
    float4 PosO : POSITION ,
    float3 NormO : NORMAL ,
    float4 TexCd : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    TexCd = mul(TexCd, tTex);
    
    
    float4 PlacingData = tex2Dlod(SampPlace, TexCd); 
    float4 PlaceCoords = float4(PlacingData.xy, 0, 1);
    
    float4 particleData = tex2Dlod(Samp, PlaceCoords);   //position data per vertices
    float3 NormFromSurf = tex2Dlod(SampNorm, PlaceCoords); // normals from Normal texture;
 
    float pitch = asin(NormFromSurf.y)/TwoPi;
    float yaw = atan2(-NormFromSurf.x, -NormFromSurf.z)/ TwoPi;
	
	PosO *= PlacingData.w;
    PosO.y += PlacingData.z;
    float4 PosW = (particleData + float4(rotate(PosO.xyz, pitch, yaw, 0),0));//float4((PosO.y+PlacingoData.z) * NormFromSurf,0);

    NormO = rotate(NormO.xyz, pitch, yaw, 0);
    //normal in view space
    Out.NormV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    Out.ViewDirV = -normalize(mul(PosW, tWV));

    //then apply the tVP
    Out.PosWVP = mul(PosW, tVP);
    
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

technique SurfaceConstrain_Place_PhongDirectional
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}



