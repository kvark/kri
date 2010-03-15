#version 130
precision lowp float;

uniform vec4 mat_scalars;

float comp_specular(vec3 no, vec3 lit, vec3 cam)	{
	float nh = dot(no, normalize(lit+cam) );
	if(nh <= 0.0) return 0.0;
	
	float nv = max(dot(no,cam), 0.0);
	float sf = pow(nh, mat_scalars.z);
	return mat_scalars.y * sf/(0.1+nv);
}
