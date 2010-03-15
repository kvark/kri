#version 130
precision lowp float;

in vec3 at_tex;

vec4 tc_bump()	{
	return vec4(at_tex,0.0);
}