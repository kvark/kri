#version 130

uniform sampler2D unit_input;

noperspective in vec2 tex_coord;

void main()	{
	float d00 = texture(unit_input, tex_coord).r;
	float d10 = textureOffset(unit_input, tex_coord, ivec2(1,0)).r;
	float d01 = textureOffset(unit_input, tex_coord, ivec2(0,1)).r;
	float d11 = textureOffset(unit_input, tex_coord, ivec2(1,1)).r;
	gl_FragDepth = max( max(d00,d10), max(d01,d11) );
}
