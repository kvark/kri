#version 130
precision lowp float;

out vec4 coord_texture;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;

vec4 fixed_proj(Spatial,vec4);
vec4 tc_texture();

void main()	{
	gl_Position = fixed_proj(s_cam,proj_cam);
	coord_texture = tc_texture();
}
