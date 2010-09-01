#version 130

uniform float limit;
uniform vec4 cur_time;

float part_uni();


bool born_ready()	{
	float u = part_uni();
	return cur_time.y > limit*u;
}
