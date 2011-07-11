#version 130

uniform	sampler2D	unit_input[2];
out	vec4		rez;

void main()	{
	vec2 tc = vec2(0.5);
	rez	= vec4(1.0);
	for(int i=0; i<2; ++i)
		rez *= texture(unit_input[i],tc);
}
