#version 130
precision lowp float;

uniform sampler2D unit_texture;

vec4 mat_texture(vec4 tc)	{
	return texture2D(unit_texture, tc.xy);
}
