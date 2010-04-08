#version 130

uniform float mat_emissive;

vec4 get_emissive()	{
	return vec4(mat_emissive);
}