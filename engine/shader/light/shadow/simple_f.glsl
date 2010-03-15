#version 130
precision lowp float;

uniform sampler2DShadow unit_light;

float get_shadow(vec4 coord)	{
	return texture(unit_light, coord.xyz);
}