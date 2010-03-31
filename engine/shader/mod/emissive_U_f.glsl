#version 130
precision lowp float;

uniform float mat_emissive;

vec4 get_emissive()	{
	return vec4(mat_emissive);
}