#version 130
precision lowp float;

in vec3 at_tex;

uniform vec4 offset_bump, scale_bump;

vec4 tc_bump()	{
	return offset_bump + vec4(at_tex,0.0)*scale_bump;
}