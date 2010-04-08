#version 130

uniform float mat_emissive;
uniform sampler2D unit_emissive;

in vec4 tc_emissive;

vec4 get_emissive()	{
	return mat_emissive * texture(unit_emissive, tc_emissive.xy);
}
