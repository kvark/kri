#version 130

uniform sampler2D unit_mirror;
uniform vec4 mirror_color;

vec4 tc_mirror();

vec4 get_mirror()	{
	return mirror_color * texture( unit_mirror, tc_mirror().xy );
}
