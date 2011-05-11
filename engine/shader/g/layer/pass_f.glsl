#version 130

uniform	sampler2D	unit_texture;
uniform	float		zero;
uniform vec4		user_color;
uniform	vec4		mask_diffuse;
uniform	vec4		mask_specular;
uniform	vec4		mask_normal;

out	vec4	c_diffuse;
out	vec4	c_specular;
out	vec4	c_normal;

vec4	tc_unit();
const	vec3	luminance = vec3(0.3,0.5,0.2);


void main()	{
	vec4	tc	= tc_unit(), z4 = vec4(zero);
	vec4	value	= texture( unit_texture, tc.xy );
	if (value.w<0.01)	discard;

	vec4	alt	= vec4(user_color.xyz,1.0) * dot(value.xyz,luminance);
	vec4	color	= mix( value, alt, user_color.w );
	color.w	= dot(color.xyz,color.xyz);
	
	c_diffuse	= mix( z4, color, mask_diffuse );
	c_specular	= mix( z4, color, mask_specular );
	c_normal	= mix( z4, color, mask_normal );
}
