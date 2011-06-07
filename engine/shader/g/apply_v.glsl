#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit,s_cam;
uniform vec4 range_lit, proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

in vec4 at_vertex;
flat out Spatial s_light;


void main()	{
	s_light = s_lit;
	vec3 scale = range_lit.y * vec3( range_lit.ww, 1.0 );
	vec3 v = trans_for( scale * at_vertex.xyz, s_lit );
	vec3 vc = trans_inv(v,s_cam);
	gl_Position = get_projection(vc, proj_cam);
}
