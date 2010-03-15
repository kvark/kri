#version 140
precision lowp float;

in vec2 at_sys;
in vec3 at_pos;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_model;
uniform vec4 proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

void main()	{
	gl_ClipDistance[0] = at_sys.x;
	//vec3 v = trans_for(at_pos, s_model);
	vec3 v = trans_inv(at_pos, s_cam);
	gl_Position = get_projection(v,proj_cam);
}