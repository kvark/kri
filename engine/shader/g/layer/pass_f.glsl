#version 130

uniform	float	zero;

out	vec4	c_diffuse;
out	vec4	c_specular;
out	vec4	c_normal;


vec4	tc_unit();
vec3	get_diffuse(vec4);
float	get_emission(vec4);
vec3	get_specular(vec4);
float	get_glossiness(vec4);
vec3	get_normal(vec4);


void main()	{
	vec4 tc		= tc_unit();
	c_diffuse	= vec4( get_diffuse(tc), get_emission(tc) );
	c_specular	= vec4( get_specular(tc),get_glossiness(tc) );
	c_normal	= vec4( get_normal(tc), zero );
}
