#version 130

vec4 get_diffuse();
vec4 get_specular();
vec4 get_bump();
float get_glossiness();

float comp_diffuse(vec3,vec3);
float comp_specular(vec3,vec3,vec3,float);

vec4 get_lighting(vec3 lit, vec3 cam)	{
	vec3 no = get_bump().xyz;
	float glossy = get_glossiness();
	return	comp_diffuse(no,lit) * get_diffuse() +
		comp_specular(no,lit,cam,glossy) * get_specular();
}