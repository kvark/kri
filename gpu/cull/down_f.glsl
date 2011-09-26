#version 150 core

uniform sampler2D unit_input;

noperspective in vec2 tex_coord;

void main()	{
	vec4 d = vec4(texture(unit_input, tex_coord).r,
		textureOffset(unit_input, tex_coord, ivec2(1,0)).r,
		textureOffset(unit_input, tex_coord, ivec2(0,1)).r,
		textureOffset(unit_input, tex_coord, ivec2(1,1)).r);
	gl_FragDepth = max( max(d.x,d.y), max(d.z,d.w) );
}
