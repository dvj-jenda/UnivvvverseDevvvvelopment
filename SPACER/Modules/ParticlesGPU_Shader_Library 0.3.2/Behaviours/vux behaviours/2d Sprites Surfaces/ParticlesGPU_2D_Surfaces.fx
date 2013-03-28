//@author: dottore
//@description: draws a Constant ParticlesGPU Sprites mesh using the DataTexture
//@tags: particles sprites
//@credits: Viktor Vicsek for Sprites Function

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;
float4x4 tP: PROJECTION ;
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWVP: WORLDVIEWPROJECTION;

texture TexData <string uiname="Data Texture";>;
sampler SampData = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexData);          //apply a texture to the sampler
    MipFilter = none;                    //sampler states
    MinFilter = none;
    MagFilter = none;
};

/////connect this input to the BackBufferHeight output of the renderer
float ViewportHeight;
/////decide if you want perspective
bool calcPerspective<string uiname="Calculate Scale From Perspective";>;
//yet to be done: allow rotating the TexCoords coz the quads cant be rotated
//float rotation<string uiname="Rotate Texcoords";>;


//Color Texture
texture Texture <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Texture);          //apply a texture to the sampler
    MipFilter = linear;         //sampler states
    MinFilter = linear;
    MagFilter = linear;
};

texture TexSprite <string uiname="Sprite Texture";>;
sampler SampSprite = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexSprite);          //apply a texture to the sampler
    MipFilter = LINEAR;                    //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

int Shape1 = 0;
int Shape2 = 1;

float Blend;

#define PI 3.14159265

float4 Color :COLOR = 1;

float CyclesU = 1.0;
float CyclesV = 1.0;
float RipplesAmp = 0;
float RipplesFreq = 20;
float RipplesTime = 0.0;
float SpriteScale = 1.0;

float3 VolumeScale = 1.0;
float3 VolumeOffset = 0.0;

void Ripple(inout float4 p,float u,float v)
{
	u = (u + 0.5) * PI * 2 * CyclesU;
    v = (v + 0.5) * PI * CyclesV;
    p.x += cos(RipplesFreq*v + RipplesTime)*RipplesAmp;
    p.y += cos(RipplesFreq*u + RipplesTime)*RipplesAmp;
}


// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------



void Sphere(float u,float v, out float4 p)
{
	u = (u + 0.5) * PI * 2 * CyclesU;
    v = (v + 0.5) * PI * CyclesV;
	float su = sin(u); float sv = sin(v); float cu = cos(u); float cv = cos(v);
	p.x = su*sv;
	p.y = cu*sv;
	p.z = cv;
	p.w = 1;
	
}

void AstroidalEllipse(float u,float v, out float4 p)
{
	u = (u + 0.5) * PI * 2 * CyclesU;
    v = (v + 0.5) * PI * CyclesV;
	float su = sin(u); float sv = sin(v); float cu = cos(u); float cv = cos(v);
	p.x = pow(su*sv,3);
	p.y = pow(cu*sv,3);
	p.z = pow(cv,3);
	p.w = 1;

}


void MaederOwl(float u, float v,out float4 p)
{
	 u = (u + 0.5) * 4 * PI * CyclesU;
	 v += 0.5;
     p.x = v*cos(u) - 0.5*v*v*cos(2*u);
     p.y = -v * sin(u) - 0.5 * v*v*sin(2*u);
     p.z = 4 * pow(v,1.5)*cos(3*u/2)/3;
     p.w = 1;
         
}

void Apple(float u,float v,out float4 p)
{
	 u = (u + 0.5) * 2 * PI * CyclesU;
	 v = ((v * 2 * PI) - PI) * CyclesV;
     p.x = cos(u)* (4 + 3.8 *cos(v));
     p.y  = sin(u)* (4 + 3.8 *cos(v));
     p.z = (cos(v) + sin(v) - 1)* (1 + sin(v))*
     log(1 - PI* v/10) + 7.5*sin(v);
     p.w = 1;

}

void Horn(float u,float v, out float4 p)
{
	u = (u + 0.5) * CyclesU;
    v = (v + 0.5) * 2 * PI * CyclesV;
    p.x = (2 + u*cos(v))* sin(2*PI*u);
    p.y = (2 + u*cos(v))* cos(2*PI*u) + 2*u  ;
    p.z = u*sin(v);
	p.w = 1;
}

void TriaxialHexaTorus(float u,float v, out float4 p)
{
    u = (u + 0.5) * 2 * PI * CyclesU;
    v = (v * 2 * PI) * CyclesV;
    p.x = sin(u) / (sqrt(2) + cos(v));
    p.y = sin(u+2*PI/3) / (sqrt(2) + cos(v+2*PI/3));
    p.z = cos(u-2*PI/3) / (sqrt(2) + cos(v-2*PI/3));
	p.w = 1;
}

void TranguloidTrefoil(float u,float v, out float4 p)
{
    u = ((u * 2 * PI) - PI) * CyclesU;
    v = ((v * 2 * PI) - PI) * CyclesV;
    p.x = 2*sin(3*u)/(2+cos(v));
    p.y = 2*(sin(u) + 2*sin(2*u))/(2+cos(v+2*PI/3));
    p.z = (cos(u)-2*cos(2*u))*(2+cos(v))*(2+cos(v+2*PI/3))/4;
	p.w = 1;
}


void Crescent(float u,float v, out float4 p)
{
	u = (u + 0.5) * CyclesU;
    v = (v + 0.5) * CyclesV;
    p.x = (2 + sin(2*PI*u)*sin(2*PI*v))*sin(3*PI*v);
    p.y = (2 + sin(2*PI*u)*sin(2*PI*v))*cos(3*PI*v) ;
    p.z = cos(2*PI*u)*sin(2*PI*v) + 4*v - 2;
	p.w = 1;
}

const int SHAPE_COUNT = 8;

void ApplyFormula(int idx,float u,float v,out float4 p)
{
	idx = idx % SHAPE_COUNT;
	if (idx == 0) { Sphere(u,v,p); }
	if (idx == 1) { AstroidalEllipse(u,v,p); }
	if (idx == 2) { MaederOwl(u,v,p); }
	if (idx == 3) { Apple(u,v,p); }
	if (idx == 4) { Horn(u,v,p); }
	if (idx == 5) { TriaxialHexaTorus(u,v,p); }
	if (idx == 6) { TranguloidTrefoil(u,v,p); }
	if (idx == 7) { Crescent(u,v,p); }

}


struct vs2ps
{
    float4 Pos : POSITION ;
    float4 TexCd2 : TEXCOORD2 ;
    float Size : PSIZE ;
};


// VERTEXSHADERS

vs2ps VS(
    float4 PosO : POSITION ,
    float4 TexCd : TEXCOORD0 ,
    float4 TexCd2 : TEXCOORD2 )
{
    //inititalize all fields of output struct with 0
    
    vs2ps Out = (vs2ps)0;

    //Transform Data from Transform texture
    
    float4 particleTransform = tex2Dlod(SampData, TexCd);
    
    //PosO = mul(PosO, tW);
    //PosO.xy += particleTransform.xy;
    
   // float u,v;
    //u = (particleTransform.x + 0.5) * PI * 2 * CyclesU ;
    //v = (particleTransform.y + 0.5) * PI * CyclesV;
    
    float4 b1,b2;
    ApplyFormula(Shape1,particleTransform.x,particleTransform.y,b1);
    ApplyFormula(Shape2,particleTransform.x,particleTransform.y,b2);
    
    PosO = lerp(b1,b2,Blend);
    Ripple(PosO,particleTransform.x,particleTransform.y); 
    
    
    Out.Pos = mul(PosO, tWVP);
    //Out.Pos.w = particleTransform.a;
    //Out.TexCd1.xy = PosO.xy;
    Out.TexCd2 = PosO;
    
    if(calcPerspective)
    {
       Out.Size = SpriteScale * particleTransform.z * tP / Out.Pos.w * ViewportHeight/2;
    }
    else
    {
         Out.Size = particleTransform.z * SpriteScale;
    }
    return Out;
}

// PIXELSHADERS:

float4 PS(vs2ps In): COLOR
{
    float4 col = tex3D(SampSprite, In.TexCd2 * VolumeScale + VolumeOffset) * Color;
    
    //col *= tex2D(SampSprite,In.Pos.xy);
    
    return col;
}

float4 PSSprite(vs2ps In): COLOR
{
    float4 col = tex2D(Samp, In.TexCd2) * Color;
    
    //col *= tex2D(SampSprite,In.Pos.xy);
    
    return col;
}


// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique Particles_2d_Sprites
{
pass P0
     {
/////the next 3 statements are important:
     FillMode = POINT;
     PointScaleEnable = true;
     PointSpriteEnable = true;   
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PSSprite();
     }
}

technique Particles_2d_scale
{
pass P0
     {
/////the next 3 statements are important:
     FillMode = POINT;
     PointScaleEnable = true;
     //PointSpriteEnable = true;   
     VertexShader = compile vs_3_0 VS();
     PixelShader = compile ps_3_0 PS();
     }
}
