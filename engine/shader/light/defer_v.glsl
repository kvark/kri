#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 range_lit, proj_cam;

vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

in vec4 at_vertex;
out vec3 lit_pos;


void main()	{
	vec3 v = range_lit.y * at_vertex.xyz + s_lit.pos.xyz;
	vec3 vc = trans_inv( v, s_cam );
	lit_pos = trans_inv( s_lit.pos, s_cam );
	gl_Position = get_projection(vc, proj_cam);
}