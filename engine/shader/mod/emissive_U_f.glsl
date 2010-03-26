#version 130
precision lowp float;

uniform vec4 mat_emissive;

vec4 get_emissive()	{
	return mat_emissive;
}