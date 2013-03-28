//@author: dottore
//@description: 2d Position Velocity Cycle texture
//@tags: particles dynamic texture 
//@credits: 

//transforms
float4x4 tW: WORLD;

//texture A: position of the last frame
texture PosQueue <string uiname="Position";>;
sampler SampQueue = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (PosQueue);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
};

//texture B: reset position
texture ResPos <string uiname="RG=Pos,BA=Vel Reset Value";>;
sampler SampResPos = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (ResPos);          //apply a texture to the sampler
    MipFilter = none;         //sampler states
    MinFilter = none;
    MagFilter = none;
    addressU = wrap;
};


float2 Gravity = float2(0.0f,-1.0f);
float2 AttractorPos;
bool Apply = false;
float AttractorRadius = 1.0f;
float AttractorForce = 1.0f;
float Dt = 0.2f;
float Damping = 1.0f; 

float2 BoundsMin = float2(-10.0f,-10.0f);
float2 BoundsMax = float2(10.0f,10.0f);

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

float2 XYres;
float emitterCount;
float emitIndex;
float emitIndexPrev;

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 Pos  : POSITION,
    float4 TexCd : TEXCOORD0)
{
    //declare output struct
    vs2ps Out;
    
    //transform position
    Out.Pos = mul(Pos,tW);
    
    //transform texturecoordinates
    Out.TexCd = TexCd;

    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS1(vs2ps In): COLOR
{
    float4 posQueue = tex2D(SampQueue, In.TexCd);   
    
    bool ResBang = 0;
    float index = In.TexCd.x*XYres.x + In.TexCd.y*XYres.x*XYres.y;       
    if(emitIndex >= emitIndexPrev)
      { ResBang = index > emitIndexPrev && index <= emitIndex;}
    else
      { ResBang = 1-(index < emitIndexPrev && index >= emitIndex); }
    
 /*   float indexU = 0;
    if(emitIndex >= emitIndexPrev)
      { indexU = (index - emitIndexPrev)/emitterCount ;}  
    else
      { indexU = 1-(index < emitIndexPrev && index >= emitIndex); }
 */   
    
    float4 resetPos = tex2D(SampResPos, float2(index/emitterCount,0));
    
if(ResBang)
         {
         return resetPos;
         }
         else
         {
         posQueue.ba += Gravity * Dt;
         if (Apply)
         {
            float2 diff = AttractorPos -  posQueue.rg;
            float dsq = dot(diff,diff);
            if (dsq < AttractorRadius*AttractorRadius)
            {
            	float d= sqrt(dsq);
            	
            	float2 force = AttractorForce * (1.0f / d) * diff;
            	
            	posQueue.ba += force * Dt;
            	
            }
         }
         posQueue.rg += posQueue.ba * Dt;
         bool reflecx = false;
         bool reflecy = false;
         //float2 reflec = float2(1.0f,1.0f);
         if (posQueue.r < BoundsMin.x)
         {
         	posQueue.r = BoundsMin.x;
         	//reflec.x *= -1;
         	reflecx = true;
         }
         if (posQueue.r > BoundsMax.x)
         {
         	posQueue.r = BoundsMax.x;
         	//reflec.x *= -1;
         	reflecx = true;
         }
         if (posQueue.g < BoundsMin.y)
         {
         	posQueue.g = BoundsMin.y;
         	//reflec.y *= -1;
         	reflecy = true;
         }
         if (posQueue.g > BoundsMax.y)
         {
         	posQueue.g = BoundsMax.y;
         	//reflec.y *= -1;
         	reflecy = true;
         }
         
         posQueue.b = reflecx ? -posQueue.b : posQueue.b;
         posQueue.a = reflecy ? -posQueue.a : posQueue.a;
         posQueue.ba *= Damping;
         
         
         return posQueue;
         }
         
}



// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Fields_to_Position
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS1();
    }
}


