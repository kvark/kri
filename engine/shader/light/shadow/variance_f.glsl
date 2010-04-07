#version 130
precision lowp float;

uniform sampler2D unit_light;
in float lit_depth;

vec4 get_sample(vec2 tc)	{
	vec4 center = texture(unit_light, tc);
	return center;
	return	0.2 * textureOffset(unit_light, tc, ivec2(0,3)) +
		0.2 * textureOffset(unit_light, tc, ivec2(-2,-1)) +
		0.2 * textureOffset(unit_light, tc, ivec2(+2,-1)) +
		0.4 * center;
}

float get_shadow(vec4 sc)	{
	vec4 mo = get_sample( sc.xy );
	//return step(lit_depth - 1e-6, mo.x);
	float r = lit_depth - mo.x, r2 = r*r;
	float s2 = max(1e-5, mo.y - mo.x*mo.x);
	return s2 / (s2 + r2);
}