#version 130
precision lowp float;

uniform vec4 base_color;

vec4 get_emissive();

in vec4 tc_emissive;

void main()	{
	//gl_FragColor = tc_emissive;
	gl_FragColor = base_color + get_emissive();
}
