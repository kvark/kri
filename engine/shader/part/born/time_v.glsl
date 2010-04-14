#version 130

uniform vec4 part_life;

vec3 part_time();
vec2 part_uni();


bool born_ready()	{
	float t = part_time().z;
	vec2 u = part_uni();
	return t > u.x*part_life.z && u.y < part_life.w;
}
