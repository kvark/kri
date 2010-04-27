#version 130

uniform float mat_emissive;
uniform sampler2D unit_emissive;

vec4 tc_emissive();

vec4 get_emissive()	{
	vec2 tc = tc_emissive().xy;
	return mat_emissive * texture(unit_emissive,tc);
}
