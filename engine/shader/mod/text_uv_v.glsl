#version 130
precision lowp float;

in vec3 at_tex;

uniform vec4 offset_texture, scale_texture;

vec4 tc_texture()	{
	return offset_texture + vec4(at_tex,0.0)*scale_texture;
}