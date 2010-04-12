#version 130

uniform vec4 part_life;
uniform float limit;

vec3 part_time();
vec2 part_uni();


bool born_ready()	{
	vec3 t = part_time();
	vec2 u = part_uni();
	return t.z > limit*u.x;
}
