#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;


vec4	fixed_proj(Spatial,vec4);
vec4	get_quaternion();
void	make_tex_coords();

in	vec4	at_vertex;
out	vec4	n_space;
out	float	handiness;


void main()	{
	make_tex_coords();
	gl_Position = fixed_proj(s_cam,proj_cam);
	handiness = at_vertex.w;
	n_space = get_quaternion();
}
