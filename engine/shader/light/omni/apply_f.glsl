#version 130
precision lowp float;

const int nLayers = 2;

uniform struct Material	{
	vec4 emissive;
	vec4 diffuse;
	vec4 specular;
}mat;

uniform vec4 lit_color, lit_data, proj_lit;

float comp_diffuse(vec3,vec3);
float comp_specular(vec3,vec3,vec3);
vec4 mat_texture(vec4);
vec4 mat_bump(vec4);
vec4 mat_shift(vec4,vec3);

in vec3 v2lit, v2cam;
in vec4 v_shadow;
in float lit_int, lit_side;
in vec4 coord_text, coord_bump;

uniform samplerCubeShadow unit_light;

float get_shadow()	{
	//return texture(unit_light, v_shadow);
	return 1.0;
}

void main()	{
	vec3 v_lit = normalize(v2lit);
	vec3 v_cam = normalize(v2cam);
	vec4 tc = mat_shift(coord_text,v_cam);
	
	float intensity = lit_int * get_shadow();
	if(intensity < 0.01) discard;
	
	vec4 text = mat_texture(tc);
	vec4 bump = mat_bump(tc);
	
	gl_FragColor = intensity*lit_color * (
		mat.diffuse * text * comp_diffuse(bump.xyz,v_lit) +
		mat.specular * comp_specular(bump.xyz,v_lit,v_cam) );
	return;
}
