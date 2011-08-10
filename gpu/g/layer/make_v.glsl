#version 150 core

uniform struct Spatial	{
	vec4	pos,rot;
}s_model,s_cam;

uniform vec4	proj_cam;


vec4 fixed_proj(Spatial,vec4);
vec3 make_normal(vec4);

out	vec3	normal;


void main()	{
	normal = make_normal( s_model.rot );
	gl_Position = fixed_proj(s_cam, proj_cam);
}
