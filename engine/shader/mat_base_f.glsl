#version 130
precision lowp float;

uniform vec4 base_color;
uniform float factor;

vec4 get_emissive();

in vec4 tc_emissive;

void main()	{
	gl_FragColor = base_color + factor * get_emissive();
}
