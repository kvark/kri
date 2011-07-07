#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_target;

vec3 fixed_trans(Spatial);

vec3 mi_object()	{
	return fixed_trans(s_target);
}
