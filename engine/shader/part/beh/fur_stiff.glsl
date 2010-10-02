#version 130

uniform vec4 cur_time, fur_system;
uniform float fur_stiff;
//todo: use physically correct stiffness

in	vec3 at_prev, at_base;
out	vec3 to_pos, to_speed;


float update_stiff()	{
	vec3 sof = to_pos + at_prev - 2.0*at_base;
	float kd = 1.0 / max(0.001,cur_time.x);
	float value = fur_system.x*fur_stiff*cur_time.x;
	to_speed -= min(value,kd) * sof;
	return 1.0;
}
