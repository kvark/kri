#version 130

in	vec3 at_prev, at_base;
out	vec3 to_pos, to_speed;

uniform vec4 cur_time;


float update_norm()	{
	vec3 old = to_pos;
	float dist = length(at_base - at_prev);
	vec3 dir = normalize(to_pos - at_base);
	to_pos = at_base + dist * dir;
	// invisible force estimation
	to_speed += (to_pos - old) / max(0.001,cur_time.x);
	return 1.0;
}
