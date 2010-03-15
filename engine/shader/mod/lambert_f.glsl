#version 130
precision lowp float;

uniform vec4 mat_scalars;

float comp_diffuse(vec3 no, vec3 lit)	{
	return mat_scalars.x * max( dot(no,lit), 0.0);
}