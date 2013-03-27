// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//texture size XY
float2 size_source;
float patchesCount;

//filter texture
texture TexFilter <string uiname="Filter Texture";>;

//filter sampler
sampler1D SampFilter = sampler_state
{
    Texture   = (TexFilter);     //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
    addressU = wrap;
    addressV = wrap;
};

float3 filter(float x)
{
  x = frac(x);
  float x2 = x*x;
  float x3 = x2*x;
  float w0 = (  -x3 + 3*x2 - 3*x + 1)/6.0;
  float w1 = ( 3*x3 - 6*x2       + 4)/6.0;
  float w2 = (-3*x3 + 3*x2 + 3*x + 1)/6.0;
  float w3 = x3/6;
  
  float h0 = 1 - w1/(w0+w1) + x;
  float h1 = 1 + w3/(w2+w3) - x;
  
  return float3(h0, h1, w0+w1);
}

bool UseKernelTexture;

//texture lookup
float4 tex2Dbicubic(sampler s, float2 tex)
{

//pixel size XY
  float2 pix = 1.0/size_source;

  //calc filter texture coordinates  
  float2 w = tex*size_source-float2(0.5, 0.5);
  
  //u = clamp(u, patchIndex/patchesCount, (patchIndex+1)/patchesCount); //natan  //wrong

  // fetch offsets and weights from filter function
  float3 hg_x = UseKernelTexture ? tex1D(SampFilter, w.x ).xyz : filter(-w.x);
  float3 hg_y = UseKernelTexture ? tex1D(SampFilter, w.y ).xyz : filter(-w.y);

  float2 e_x = {pix.x, 0};
  float2 e_y = {0, pix.y};

  // determine linear sampling coordinates
  float2 coord_source10 = tex + hg_x.x * e_x;
  float2 coord_source00 = tex - hg_x.y * e_x;
  float2 coord_source11 = coord_source10 + hg_y.x * e_y;
  float2 coord_source01 = coord_source00 + hg_y.x * e_y;
  coord_source10 = coord_source10 - hg_y.y * e_y;
  coord_source00 = coord_source00 - hg_y.y * e_y;
  
  float patchIndex = floor(tex.x * patchesCount); 
  float min = patchIndex/patchesCount+pix.x*0.5;
  float max = (patchIndex+1)/patchesCount-pix.x*0.5;
  coord_source00.x = clamp(coord_source00.x, min, max);
  coord_source10.x = clamp(coord_source10.x, min, max);
  coord_source01.x = clamp(coord_source01.x, min, max);
  coord_source11.x = clamp(coord_source11.x, min, max);

  // fetch four linearly interpolated inputs
  float4 tex_source00 = tex2D( s, coord_source00 );
  float4 tex_source10 = tex2D( s, coord_source10 );
  float4 tex_source01 = tex2D( s, coord_source01 );
  float4 tex_source11 = tex2D( s, coord_source11 );

  // weight along y direction
  tex_source00 = lerp( tex_source00, tex_source01, hg_y.z );
  tex_source10 = lerp( tex_source10, tex_source11, hg_y.z );

  // weight along x direction
  tex_source00 = lerp( tex_source00, tex_source10, hg_x.z );

  return tex_source00;
}

// -------------------------------------------------------------------------

