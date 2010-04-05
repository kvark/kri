#version 130
precision lowp float;

in vec2 tex_coord;
uniform sampler2D unit_input;

void main()	{
	gl_FragColor = 0.4* texture(unit_input, tex_coord) + 
		0.2 * textureOffset(unit_input, tex_coord, ivec2(0,-1)) + 
		0.2 * textureOffset(unit_input, tex_coord, ivec2(0,+1)) + 
		0.1 * textureOffset(unit_input, tex_coord, ivec2(0,-2)) + 
		0.1 * textureOffset(unit_input, tex_coord, ivec2(0,+2)) ;
}
