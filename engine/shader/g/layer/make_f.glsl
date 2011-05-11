#version 130

uniform	vec4	mat_emissive;
uniform	vec4	mat_diffuse;
uniform	vec4	mat_specular;
uniform	float	mat_glossiness;

in	vec4	normal;
out	vec4	c_diffuse;
out	vec4	c_specular;
out	vec4	c_normal;


void main()	{
	vec3 norm = vec3(0.5) + 0.5*normalize(normal.xyz);
	float glossy = 0.01 * mat_glossiness;
	vec3 emi = mat_emissive.xyz, diff = mat_diffuse.xyz;
	
	c_diffuse	= vec4( diff, dot(diff,emi) );
	c_specular	= vec4( mat_specular.xyz, glossy );
	c_normal	= vec4( norm, normal.w );
}
