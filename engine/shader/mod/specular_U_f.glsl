#version 130
precision lowp float;

uniform vec4 mat_specular;

vec4 get_specular()	{
	return mat_specular;
}