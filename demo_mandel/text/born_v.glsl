#version 130

uniform float limit;

vec4 part_time();
float part_uni();


bool born_ready()	{
	vec4 t = part_time();
	float u = part_uni();
	return t.z > limit*u;
}
