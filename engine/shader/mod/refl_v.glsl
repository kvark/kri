#version 130
precision lowp float;

in vec3 at_vertex;

vec4 tc_reflect()	{
	return vec4(at_vertex,0.0);
}