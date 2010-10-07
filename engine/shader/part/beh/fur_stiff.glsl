#version 130

uniform vec4 cur_time, fur_system;
uniform float fur_stiff;
//todo: use physically correct stiffness

in	vec3 at_prev, at_base;
out	vec3 to_pos, to_speed;


float update_stiff()	{
	vec3 newpos = to_pos;// + 0.5*cur_time.x * to_speed;
	vec3 sof = 2.0*at_base - newpos - at_prev;
	float kt = fur_system.x*fur_stiff*cur_time.x;
	//float kd = 1.0 / max(0.001,cur_time.x);
	//float kmax = kd - dot(to_speed,sof) / dot(sof,sof);
	to_speed += kt * sof;
	return 1.0;
}
