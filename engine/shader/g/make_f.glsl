#version 130

uniform float mat_emissive;

vec4 get_bump();
vec4 get_diffuse();
vec4 get_specular();
float get_glossiness();

vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

flat in float handness;
in vec4 quat;
in vec4 coord_text, coord_bump;

out vec4 c_diffuse;
out vec4 c_specular;
out vec4 c_normal;


void main()	{
	vec3 bump = get_bump().xyz * vec3(handness,1.0,1.0);
	vec3 w_norm = qrot(normalize(quat), bump);
	float glossy = 0.01 * get_glossiness();
	
	c_diffuse	= vec4( get_diffuse().xyz, mat_emissive );
	c_specular	= get_specular();
	c_normal	= vec4(vec3(0.5) + 0.5*w_norm, glossy);
}
