#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_target;

vec3 fixed_trans(Spatial);
vec3 trans_inv(Spatial,vec3);

vec3 mi_object()	{
	vec3 v = fixed_trans(s_cam);
	return trans_inv(s_target,v);
}
