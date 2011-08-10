#version 150 core

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;

void make_tex_coords();
vec4 fixed_proj(Spatial,vec4);

void main()	{
	make_tex_coords();
	gl_Position = fixed_proj(s_cam,proj_cam);
}
