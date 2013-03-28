//@author: vvvv group
//@help: this is a very basic template. use it to start writing your own effects. if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tWVP: WORLDVIEWPROJECTION ;

//texture1
texture Tex1 <string uiname="Previous Pass Texture";>;
sampler Data = sampler_state   
{
    Texture   = (Tex1);          
    MipFilter = none;         
    MinFilter = none;
    MagFilter = none;
};

//texture2
texture Tex2 <string uiname="Position Texture";>;
sampler DataPosition = sampler_state    
{
    Texture   = (Tex2);         
    MipFilter = none;       
    MinFilter = none;
    MagFilter = none;
};

float3 camPos <string uiname="Camera Position";>;
bool reset <string uiname="Reset";>;

uniform float3 Param1;
uniform float3 Param2;

// contents of the uniform data fields
#define GroupSize Param1.x    // Sub-groups size (2,4,4,8,8,8,16,16,16,16, ...
#define Width Param1.y        // x resolution
#define Height Param1.z       // y resolution

#define distPartner Param2.x  // distance of the partner to compare
#define offsetDown Param2.y   // inferior bound from where active cells start
#define offsetUp Param2.z     // superior bound where active cells end



struct vs2ps
{
    float4 Pos  : POSITION ;
    float2 TexCd : TEXCOORD0 ;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION ,
    float4 TexCd : TEXCOORD0 )
{
    //declare output struct
    vs2ps Out;
    //transform position
    Out.Pos = mul(PosO, tWVP);
    //transform texturecoordinates
    Out.TexCd = TexCd;
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(vs2ps In): COLOR
{
  // get the index in the array
  float i = floor(In.TexCd.x * Width) + floor(In.TexCd.y * Height) * Width;
 
  // get self data from the last frame texture
  float4 self = tex2D(Data, In.TexCd.xy);  
  
  // my position within the sub-group to merge
  float j = floor(fmod(i, GroupSize));
  
  float compare;
  float direction; 
  float4 SortedValue;

  // find if the pixel is in the active interval of the sub-group
  bool active = (j >= offsetDown) && (j <= offsetUp);
  
  if (!active) //inactive
     {
      // must copy -> compare with self
      compare = 0.0;
      SortedValue = self;
     }
    
  else
     {
      // must sort

      // find the direction where to find the partner (1 = right , 0 = left)
      direction = fmod(((j + offsetDown) / distPartner) , 2) >= 1;
          
            if (direction)  // we are on the right side -> compare with partner on the left
               compare = -1.0;

               else         // we are on the left side -> compare with partner on the right
               compare = 1.0;

      // get the partner index in the array
      float adr = i + (compare * distPartner);
      // convert the array index in UV coordinates and get the partner's data from data texture
      float4 partner = tex2D(Data, float2(floor(fmod(adr, Width)) / Width,
                                          floor(adr / Width) / Height));
     
      // compare vales; on left is < , on right is >=
      if (direction) { SortedValue = (self.x >=  partner.x) ? partner : self; }
      else           { SortedValue = (self.x <   partner.x) ? partner : self; }
     }



  
  if(reset) { SortedValue.y = i; }  //array index reset on Reset
  
  // Update the sorted Key value (distance from Camera)
  
  // Get Position from incoming position texture using the index from the sorted values
  float3 getPos = tex2D(DataPosition, float2(floor(fmod(SortedValue.y, Width)) / Width,
                                     floor(SortedValue.y / Width) / Height)).xyz;
  // evaluate the new distance from Camera
  float newDist = length(camPos - getPos);  
  // update the key value
  SortedValue.x = newDist;
  
  return SortedValue;

}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}

