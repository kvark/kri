#version 130
//#define COMPENSATE

uniform vec4 cur_time, fur_segment;

in	vec3 at_base;
out	vec3 to_pos, to_speed;


float update_norm()	{
	vec3 old = to_pos;
	vec3 dir = normalize(to_pos - at_base);
	to_pos = at_base + fur_segment.x * dir;
	#ifdef COMPENSATE
	to_speed += (to_pos-old) / max(0.01,cur_time.y);
	#endif
	return 1.0;
}
