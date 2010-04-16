#version 130

in vec4 at_vertex;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit,s_cam;
uniform vec4 range_lit, proj_cam;

vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

void main()	{
	vec3 v = range_lit.y * at_vertex.xyz + s_lit.pos.xyz;
	vec3 vc = trans_inv(v,s_cam);
	gl_Position = get_projection(vc, proj_cam);
}
