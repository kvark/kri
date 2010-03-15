#version 130
precision lowp float;

out vec3 pos;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;

vec3 fixed_proj(Spatial);

void main()	{
	pos = fixed_proj(s_lit);
}
