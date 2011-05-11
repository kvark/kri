#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;


vec4 fixed_proj(Spatial,vec4);
void make_tex_coords();


void main()	{
	make_tex_coords();
	gl_Position = fixed_proj(s_cam,proj_cam);
}
