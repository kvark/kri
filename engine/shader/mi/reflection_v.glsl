#version 130
precision lowp float;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;

vec3 dir_world(vec3);
vec3 fixed_trans(Spatial);

vec3 mi_reflection()	{
	vec3 vcam = normalize( fixed_trans(s_cam) );
	vec3 vnor = dir_world( vec3(0.0,0.0,1.0) );
	return reflect(-vcam,vnor);
}
