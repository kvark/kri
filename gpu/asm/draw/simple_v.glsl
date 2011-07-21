#version 130

in	vec4	at_vertex;
in	vec4	at_quat;
in	vec4	at_tex;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;

uniform	vec4 proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


void main()	{
	vec3 v = trans_inv( at_vertex.xyz, s_cam );
	gl_Position = get_projection( v, proj_cam );
}