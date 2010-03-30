#version 130
precision lowp float;

uniform vec4 lit_color, lit_data, proj_lit;
uniform samplerCubeShadow unit_light;

vec4 get_diffuse();
vec4 get_specular();
vec4 get_bump();
float get_glossiness();

float get_shadow()	{
	//return texture(unit_light, v_shadow);
	return 1.0;
}
vec4 comp_diffuse(vec3 no, vec3 lit)	{
	return get_diffuse() * max( dot(no,lit), 0.0);
}
vec4 comp_specular(vec3 no, vec3 lit, vec3 cam)	{
	vec3 ha = normalize(lit+cam);	//half-vector
	float nh = max( dot(no,ha), 0.0);
	return get_specular() * pow(nh, get_glossiness());
}


in vec3 v2lit, v2cam;
in vec4 v_shadow;
in float lit_int, lit_side;

void main()	{
	vec3 v_lit = normalize(v2lit);
	vec3 v_cam = normalize(v2cam);
	
	float intensity = lit_int * get_shadow();
	if(intensity < 0.01) discard;
	
	vec3 normal = get_bump().xyz;

	gl_FragColor = intensity*lit_color * (
		comp_diffuse (normal,v_lit) +
		comp_specular(normal,v_lit,v_cam) );	
}
