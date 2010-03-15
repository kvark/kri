#version 130
precision lowp float;

uniform vec4 mat_scalars;

float comp_specular(vec3 no, vec3 lit, vec3 cam)	{
	float rez = max( dot(cam, reflect(-lit,no) ), 0.0);
	return mat_scalars.y * pow(rez, mat_scalars.z);
}