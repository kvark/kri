#version 130

uniform sampler2D unit_wave, unit_kern, unit_town;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 lit_color, lit_data;
uniform vec4 town_pos;	//X=dist, Y=scale

noperspective in vec2 tex_coord;
out vec4 rez_color;

const float eta	= 0.75;	//air->water angular fraction
const vec4 mat_consume = vec4(0.9,0.5,0.2,0.0);
const vec4 mat_specular	= vec4(1.0);
const float glossiness	= 1000.0;
const float z_off = 1.0, z_scale = 1.0;
const vec2 size = vec2(2.0,0.0);


void main()	{
	const ivec3 off = ivec3(-1,0,1);
	vec4 wave = texture(unit_wave, tex_coord);
	float s11 = wave.x;

	//rez_color = vec4(texture(unit_kern,tex_coord)); return;
	rez_color = vec4(s11+0.5); return;
	
	float s01 = textureOffset(unit_wave, tex_coord, off.xy).x;
	float s21 = textureOffset(unit_wave, tex_coord, off.zy).x;
	float s10 = textureOffset(unit_wave, tex_coord, off.yx).x;
	float s12 = textureOffset(unit_wave, tex_coord, off.yz).x;
	vec3 va = normalize(vec3(size.xy,s21-s11));
	vec3 vb = normalize(vec3(size.yx,s12-s10));
	vec4 bump = vec4( cross(va,vb), s11 );
	
	float z = 0.5 - z_off - z_scale*s11;
	vec3 pos = 2.0*vec3(tex_coord,z) - vec3(1.0);
	vec3 to_lit = normalize(s_lit.pos.xyz), to_cam = vec3(0.0,0.0,1.0);
	vec3 reflected = reflect(-to_lit, bump.xyz);
	float diff = max(0.0, dot(bump.xyz, to_lit));
	float spec = max(0.0, dot(to_cam, reflected));
	float spow = pow(spec, glossiness);
	//rez_color = vec4(spow);  return;
	vec4 color = lit_color * spow * mat_specular;
	
	vec3 v_orig	= -to_cam;
	vec3 v_ref	= refract(v_orig, bump.xyz, eta);
	float dist	= town_pos.x / -v_ref.z;
	vec2 map_tc	= tex_coord + v_ref.xy * dist;
	vec4 bottom	= 0.5*texture(unit_town, map_tc);
	vec4 c_refract	= bottom * exp(-mat_consume*dist);
	float fresnel	= bump.z;
	//rez_color = vec4(-v_ref,1.0); return;
	
	//rez_color = mix(color,c_refract,fresnel);
	rez_color = c_refract + color;
}
