#version 130
precision lowp float;

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
float get_shadow(vec4);

in vec3 v2lit, v2cam;
in vec4 v_shadow;
in float lit_int;
in vec4 coord_text, coord_bump;

const int NS = 4;
const vec3 samp[] = vec3[NS](
	vec3(0.3,0.3,0.0), vec3(0.7,0.7,0.0),
	vec3(0.3,0.7,0.0), vec3(0.7,0.3,0.0)
);

void main()	{
	vec3 v_lit = normalize(v2lit);
	vec3 v_cam = normalize(v2cam);
	vec4 tc = mat_shift(coord_text,v_cam);
	
	// spot angle limit check
	vec3 vlit = v_shadow.xyz / mix(1.0, v_shadow.w, lit_data.y);
	vec2 r2 = vlit.xy;
	vec4 vs = vec4(0.5*vlit + vec3(0.5), 1.0);
	float rad = smoothstep( 0.0, lit_data.x, 1.0-dot(r2,r2) );
	float intensity = rad * lit_int * get_shadow(vs);
	//gl_FragColor = vec4(get_shadow(vs)); return;
	if(intensity < 0.01) discard;
	
	vec4 text = mat_texture(tc);
	vec4 bump = mat_bump(tc);
	
	gl_FragColor = intensity*lit_color * (
		mat.diffuse * text * comp_diffuse(bump.xyz,v_lit) +
		mat.specular * comp_specular(bump.xyz,v_lit,v_cam) );
	return;
		
	/*float ambient = 0.0;
	for(int i=0; i<NS; ++i)	{
		vec3 tc = samp[i];
		//tc.z = texture(unit_light,tc).r;	// light fragment depth
		vec2 dd = vec2(dFdx(tc.z), dFdy(tc.z));	// depth derivative
		tc = tc*2.0 - vec3(1.0);			// [-1,1] normalized coords
		float z0 = -proj_lit.w / (proj_lit.z + tc.z);	// original Z
		tc = vec3(-tc.xy / proj_lit.xy, 1.0) * z0;	// light space coords
	}*/
}
