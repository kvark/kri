#version 130
// Simplex Noise 2D

uniform sampler1D unit_perm, unit_grad;

const float F2 = (sqrt(3.0)-1.0)/2.0;
const float G2 = (3.0-sqrt(3.0))/6.0;


float get_val(vec2 pf, vec2 pi)	{
	float gi = texture(unit_perm, pi.x + texture(unit_perm,pi.y).x ).x;
	vec2 grad = texture(unit_grad, (gi*256.0+0.5)/12.0 ).xy * 2.0 - vec2(1.0);
	float t = 0.5 - dot(pf,pf), t2 = t*t;
	return step(0.0,t) * t2*t2 * dot(grad,pf);
}


float snoise(vec2 P)	{
	float ONE = 1.0 / textureSize(unit_perm,0);

	// Skew the (x,y) space to determine which cell of 2 simplices we're in
	float s = (P.x + P.y) * F2;	// Hairy factor for 2D skewing
	vec2 Pi = floor(P + vec2(s));
	float t = (Pi.x + Pi.y) * G2;	// Hairy factor for unskewing

	vec2 Pf = P - Pi + vec2(t);	// The x,y distances from the cell origin
	vec2 o1 = step( Pf.yx, Pf.xy );	// middle corner offset
	Pi = (Pi+vec2(0.5)) * ONE;	// Integer part, scaled and offset for texture lookup
	
	// Noise contribution from simplex origin
	float n0 = get_val( Pf, Pi );
	// Noise contribution from middle corner
	float n1 = get_val( Pf - o1 + G2, Pi + o1*ONE );
	// Noise contribution from last corner
	float n2 = get_val( Pf - vec2(1.0-2.0*G2), Pi + vec2(ONE) );
	
	// Sum up and scale the result to cover the range [-1,1]
	return 70.0 * (n0 + n1 + n2);
}

float get_val2(vec2 pf, float gi)	{
	vec2 grad = texture(unit_grad, (gi*256.0+0.5)/12.0 ).xy * 2.0 - vec2(1.0);
	float t = 0.5 - dot(pf,pf), t2 = t*t;
	return step(0.0,t) * t2*t2 * dot(grad,pf);
}

#define MINFETCH

float snoise2(vec2 P)	{
	float ONE = 1.0 / textureSize(unit_perm,0);
	
	// Skew the (x,y) space to determine which cell of 2 simplices we're in
	float s = (P.x + P.y) * F2;	// Hairy factor for 2D skewing
	vec2 Pi = floor(P + vec2(s));
	float t = (Pi.x + Pi.y) * G2;	// Hairy factor for unskewing

	vec2 Pf = P - Pi + vec2(t);	// The x,y distances from the cell origin
	vec2 o1 = step( Pf.yx, Pf.xy );	// middle corner offset
	Pi = (Pi+vec2(0.5))*ONE;	// Integer part, scaled and offset for texture lookup
	
	float fx0 = texture(unit_perm, Pi.x ).x;
	float f00 = texture(unit_perm, Pi.y + fx0).x;
	float fx1 = textureOffset(unit_perm, Pi.x, 1).x;
	float f11 = textureOffset(unit_perm, Pi.y + fx1, 1).x;
	
#ifdef MINFETCH	
	float mid;
	if(Pf.y < Pf.x)
		mid = texture(unit_perm, Pi.y + fx1).x;
	else	mid = textureOffset(unit_perm, Pi.y + fx0, 1).x;
#else
	float f01 = texture(unit_perm, Pi.y + fx1).x;
	float f10 = textureOffset(unit_perm, Pi.y + fx0, 1).x;
	float mid = mix( f01,f10, step(Pf.x,Pf.y) );
#endif

	// Noise contribution from simplex origin
	float n0 = get_val2( Pf, f00 );
	// Noise contribution from middle corner
	float n1 = get_val2( Pf - o1 + G2, mid );
	// Noise contribution from last corner
	float n2 = get_val2( Pf - vec2(1.0-2.0*G2), f11 );
	
	// Sum up and scale the result to cover the range [-1,1]
	return 70.0 * (n0 + n1 + n2);
}