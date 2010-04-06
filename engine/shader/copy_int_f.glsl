#version 130
precision lowp float;

uniform usampler2D unit_input;
in vec2 tex_coord;

void main()	{
	gl_FragColor = vec4(texture(unit_input, tex_coord).r);
}
