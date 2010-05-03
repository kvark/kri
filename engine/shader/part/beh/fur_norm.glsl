#version 130

in	vec3 at_prev, at_base;
out	vec3 to_pos;


float update_norm()	{
	float dist = length(at_base - at_prev);
	vec3 dir = normalize(to_pos - at_base);
	to_pos = at_base + dist * dir;
	return 1.0;
}
