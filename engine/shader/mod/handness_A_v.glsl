#version 130
precision lowp float;

in vec3 at_tex;

float get_handness()	{
	return at_tex.z;
}