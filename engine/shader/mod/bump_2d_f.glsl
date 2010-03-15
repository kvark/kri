#version 130
precision lowp float;

uniform sampler2D unit_bump;
vec3 fastnorm(vec3);	//lib_math

vec4 mat_bump(vec4 tc)	{
	vec4 bump = 2.0*texture2D(unit_bump,tc.xy) - vec4(1.0);
	bump.y *= -1.0;
	return vec4(fastnorm(bump.xyz), bump.w);
}
