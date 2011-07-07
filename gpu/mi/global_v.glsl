#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;

vec3 fixed_trans(Spatial);

vec3 mi_global()	{
	return fixed_trans(s_cam);
}
