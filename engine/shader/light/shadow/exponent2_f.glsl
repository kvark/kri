#version 130
precision lowp float;

uniform sampler2D unit_light;
uniform vec4 dark;
uniform float k_dark;
// dark.pre, dark.post, low_power, texel_offset

const int NUM = 4;
const float off = sqrt(3.0);

const vec2 offsets[] = vec2[NUM](
	vec2(0.0), vec2(0.0, 2.0),
	vec2(-off,-1.0), vec2(+off,-1.0)
);
const float wes[] = float[NUM]( 0.4, 0.2, 0.2, 0.2 );

float get_accum(vec3 coord)	{
	return texture(unit_light,coord.xy).r;
	float rez = 0.0;
	for(int i=0; i<NUM; ++i)	{
		//todo: use textureOffset()
		vec2 tc = coord.xy + dark.w * offsets[i];
		rez += wes[i] * texture(unit_light,tc).r;
	}
	return rez;
}

float get_shadow(vec4 coord)	{
	float occluder = get_accum(coord.xyz);
	float z1 = 1.0+log2(occluder)/k_dark, x = coord.z;
	float z0 = z1 + dark.z/dark.x, z2 = z0 + dark.z/dark.y;
	float R = mix(dark.x*(z1-x), dark.y*(x-z2), step(z0,x));
	//return exp2( min(0.0,R) );
	float shadow = occluder * exp2( k_dark*(1.0-coord.z) );
	return clamp(shadow, 0.0, 1.0);
}
