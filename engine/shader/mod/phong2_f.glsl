#version 130
precision lowp float;

float comp_specular(vec3 no, vec3 lit, vec3 cam, float glossy)	{
	float rez = dot(cam, reflect(-lit,no) );
	return pow( max(rez,0.0), glossy );
}