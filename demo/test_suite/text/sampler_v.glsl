#version 150 core

uniform	sampler2D	unit_input[2];
in	int		at_index;
out	vec4		rez;


void main()	{
	vec2 tc = vec2(0.5);
	if (at_index<5)
		rez = texture(unit_input[0],tc);
	else
		rez = texture(unit_input[1],tc);
}
