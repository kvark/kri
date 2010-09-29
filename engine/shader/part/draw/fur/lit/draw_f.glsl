#version 130

const vec4 mat_diffuse = vec4(0.8,0.8,0.4,1.0);
const vec4 mat_specular = vec4(0.5);
const float mat_glossiness = 80.0;

uniform vec4 lit_color, lit_data;

float get_shadow(vec4);
vec4 get_diffuse();


in vec3 fur_tan, surf_norm, dir_light, dir_view;
in vec4 color, v_shadow;
out vec4 rez_color;


void apply_shadow()	{
	return;
	vec3 vs = v_shadow.xyz * (0.5/v_shadow.w) + vec3(0.5);
	rez_color.xyz *= get_shadow( vec4(vs,1.0) );
	//rez_color.xyz = vec3( get_shadow( vec4(vs,1.0) ));
}


void main()	{
	vec3 L = normalize(dir_light);
	vec3 V = normalize(dir_view);
	vec3 T = normalize(fur_tan);

	float t_lit = dot(L,T), t_view = dot(V,T);
	vec3 n_lit = L - t_lit*T, n_view = V-t_view*T;

	float diffuse = max( 0.0, dot(L,n_lit) );
	float sq = dot(n_view,n_view) * dot(n_lit,n_lit);
	float pr_spec = sqrt(sq) - t_lit*t_view;
	float specular = pow( max(0.01,pr_spec), mat_glossiness );

	//rez_color = vec4( normalize(fur_tan), color.w );
	rez_color = diffuse * get_diffuse() + specular * mat_specular;
	rez_color.w = color.w;
	apply_shadow();
}