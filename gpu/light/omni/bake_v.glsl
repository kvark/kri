#version 150 core

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;

vec3 fixed_trans(Spatial);

out vec3 pos;


void main()	{
	pos = fixed_trans(s_lit);
}
