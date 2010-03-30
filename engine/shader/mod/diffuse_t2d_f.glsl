#version 130
precision lowp float;

uniform vec4 mat_diffuse;
uniform sampler2D unit_diffuse;

in vec4 tc_diffuse;

vec4 get_diffuse()	{
	return mat_diffuse * texture(unit_diffuse, tc_diffuse.xy);
}
