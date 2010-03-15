#version 130
precision lowp float;

uniform vec4 mat_scalars;

float comp_specular(vec3 no, vec3 lit, vec3 cam)	{
	vec3 ha = normalize(lit+cam);	//half-vector
	float nh = max( dot(no,ha), 0.0);
	return mat_scalars.y * pow(nh, mat_scalars.z);
}