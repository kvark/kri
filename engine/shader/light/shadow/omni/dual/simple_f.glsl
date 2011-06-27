#version 130

uniform sampler2DArrayShadow unit_light;

float get_shadow(vec4 coord)	{
	return texture(unit_light, coord);
}