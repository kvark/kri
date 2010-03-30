#version 130
precision lowp float;

uniform vec4 base_color;

vec4 get_emissive();

void main()	{
	gl_FragColor = base_color + get_emissive();
}
