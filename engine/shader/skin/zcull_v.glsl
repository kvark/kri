#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_model;
uniform vec4 proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

void finish(vec3 pos)	{
	vec3 vw = trans_for(pos,s_model);
	vec3 vc = trans_inv(vw,s_cam);
	gl_Position = get_projection(vc,proj_cam);
}
