#version 130
precision lowp float;

float comp_specular(vec3 no, vec3 lit, vec3 cam, float glossy)	{
	float nh = dot(no, normalize(lit+cam) );
	if(nh <= 0.0) return 0.0;
	float nv = max(dot(no,cam), 0.0);
	return pow(nh, glossy) / (0.1+nv);
}
