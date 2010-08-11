#version 130

uniform sampler2D unit_wave, unit_kern;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 lit_color, lit_data;


noperspective in vec2 tex_coord;
out vec4 rez_color;

const vec4 mat_diffuse	= vec4(0.5,0.7,1.0,0.0);
const vec4 mat_specular	= vec4(1.0);
const float glossiness	= 150.0;
const float z_off = 1.0, z_scale = 1.0;
const vec2 size = vec2(2.0,0.0);


void main()	{
	const ivec3 off = ivec3(-1,0,1);
	float s11 = texture(unit_wave, tex_coord).x;

	//rez_color = vec4(texture(unit_kern,tex_coord)); return;
	//rez_color = vec4(s11+0.5); return;
	
	float s01 = textureOffset(unit_wave, tex_coord, off.xy).x;
	float s21 = textureOffset(unit_wave, tex_coord, off.zy).x;
	float s10 = textureOffset(unit_wave, tex_coord, off.yx).x;
	float s12 = textureOffset(unit_wave, tex_coord, off.yz).x;
	vec3 va = normalize(vec3(size.xy,s21-s11));
	vec3 vb = normalize(vec3(size.yx,s12-s10));
	vec4 bump = vec4( cross(va,vb), s11 );
	
	float z = 0.5 - z_off - z_scale*s11;
	vec3 pos = 2.0*vec3(tex_coord,z) - vec3(1.0);
	vec3 to_lit = normalize(s_lit.pos.xyz), to_cam = -normalize(pos);
	vec3 reflected = reflect(-to_lit, bump.xyz);
	float diff = max(0.0, dot(bump.xyz, to_lit ));
	float spec = max(0.0, dot(to_cam, reflected ));
	float spow = pow(spec, glossiness);
	vec4 color = lit_color * (diff * mat_diffuse + spow * mat_specular);

	rez_color = color;
}
