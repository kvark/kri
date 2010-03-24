#version 130
precision lowp float;

in vec3 at_tex;

vec3 mi_uv()	{
	return at_tex;
}
