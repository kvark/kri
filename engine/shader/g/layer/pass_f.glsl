#version 130

uniform	sampler2D	unit_texture;
uniform	float		zero;
uniform vec4		user_color;
uniform	vec4		mask_diffuse;
uniform	vec4		mask_specular;

out	vec4	c_diffuse;
out	vec4	c_specular;

vec4	tc_unit();
const	vec3	luminance = vec3(0.3,0.5,0.2);


void main()	{
	vec4	tc	= tc_unit(), z4 = vec4(zero);
	vec4	value	= texture( unit_texture, tc.xy );
	if (value.w<0.01)	discard;

	float	single	= dot(value.xyz,luminance);
	vec3	alt	= single * user_color.xyz;
	vec3	color	= mix( value.xyz, alt, user_color.w );
	vec4	rez	= vec4( color, single );
	
	c_diffuse	= mix( z4, rez, mask_diffuse );
	c_specular	= mix( z4, rez, mask_specular );
}
