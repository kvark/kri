#version 130

uniform usampler2D unit_sten;
uniform sampler2D unit_color;

noperspective in vec2 tex_coord;
out uint to_sten;
out vec2 to_color;


void main()	{
	ivec2 off = ivec2(-1.0,0.0);

	//8b stencil + 24b depth
	uint t0 = texture( unit_sten, tex_coord ).x;
	uint t1 = textureOffset( unit_sten, tex_coord, off.xy ).x;
	uint t2 = textureOffset( unit_sten, tex_coord, off.yx ).x;
	uint st = max( t0&0xFF, max(t1&0xFF,t2&0xFF) );

	//color (object ID)
	vec2 c0 = texture( unit_color, tex_coord ).xy;
	to_color = c0;
	to_sten = t0;
	if(st == 0) return;

	uint k0 = step(st,t0);
	uint k1 = step(st,t1);
	uint k2 = step(st,t2);
	uint depth = k0*(t0>>8) + k1*(t1>>8) + k2*(t2>>8);
	to_sten = st + (depth<<8);

	vec2 c1 = textureOffset( unit_color, tex_coord, off.xy ).xy;
	vec2 c2 = textureOffset( unit_color, tex_coord, off.yx ).xy;
	to_color = k0*c0 + k1*c1 + k2*c2;
}