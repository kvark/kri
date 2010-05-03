#version 130

uniform vec4 cur_time;
uniform float fur_bend;
//todo: use physical correct bending

in	vec3 at_prev, at_base;
out	vec3 to_pos, to_speed;


float update_bend()	{
	vec3 sof = to_pos + at_prev - 2.0*at_base;
	float kd = 1.0 / max(0.001,cur_time.y);
	to_speed -= min( fur_bend*cur_time.y, kd ) * sof;
	return 1.0;
}
