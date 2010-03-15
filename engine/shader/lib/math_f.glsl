#version 130
precision lowp float;

vec3 fastnorm(vec3 v)	{
	return v*(1.5 - 0.5*dot(v,v));
	//return normalize(v);
}