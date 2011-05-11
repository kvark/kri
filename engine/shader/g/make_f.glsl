#version 130

//material
vec4 get_bump();
vec4 get_emissive();
vec4 get_diffuse();
vec4 get_specular();
float get_glossiness();
//deferrred
vec3 get_norm();

flat	in	float handness;
in	vec4	quat;
in	vec4	coord_text, coord_bump;

out	vec4	c_diffuse;
out	vec4	c_specular;
out	vec4	c_normal;


void main()	{
	vec3 w_norm = get_norm();
	float glossy = 0.01 * get_glossiness();
	vec3 emi = get_emissive().xyz, diff = get_diffuse().xyz;
	
	c_diffuse	= vec4( diff, dot(diff,emi) );
	c_specular	= vec4( get_specular().xyz, glossy );
	c_normal	= vec4(vec3(0.5) + 0.5*w_norm, 0.0);
}
