#version 130
precision lowp float;

uniform sampler2D unit_reflect;

vec4 mat_reflect(vec4 tc)	{
	return texture2D(unit_reflect, tc.xy);
}
