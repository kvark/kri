#version 150 core

in	vec4	at_pos, at_rot, at_par;
out	vec4	pos, rot, par;

vec4 get_proj_cam(vec3);


void main()	{
	pos = get_proj_cam(at_pos.xyz);
	rot = at_rot;
	par = get_proj_cam(at_par.xyz);
}