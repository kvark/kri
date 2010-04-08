#version 130

vec3 dir_world(vec3);

vec3 mi_tangent()	{
	return dir_world( vec3(1.0,0.0,0.0) );
}