#version 130
precision lowp float;

in vec3 at_vertex;

uniform vec4 offset_reflect, scale_reflect;

vec4 tc_reflect()	{
	return offset_reflect + vec4(at_vertex,0.0)*scale_reflect;
}