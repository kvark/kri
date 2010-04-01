#version 130
precision lowp float;

in vec2 at_tex2;

vec3 mi_uv2()	{
	return vec3(at_tex2,0.0);
}
