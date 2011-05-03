#version 130

in	vec3	normal;

vec3 get_norm()	{
	return normalize(normal);
}