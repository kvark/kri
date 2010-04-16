#version 130

vec4 get_bump();
vec4 get_diffuse();
vec4 get_specular();
float get_glossiness();

vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

float handness;
in vec4 quat;
in vec4 coord_text, coord_bump;

out vec4 c_diffuse;
out vec4 c_specular;
out vec4 c_normal;


void main()	{
	vec3 w_norm = qrot(normalize(quat), get_bump().xyz);
	w_norm.x *= handness;	//applying handness
	float glossy = 0.01 * get_glossiness();
	
	c_diffuse =	get_diffuse();
	c_specular =	get_specular();
	c_normal =	vec4(vec3(0.5) + 0.5*w_norm, glossy);
}
