#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam,halo_data;


vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

in vec2 ghost_sys;
in vec3 ghost_pos;
in vec4 at_vertex;
flat out Spatial s_light;

const float extra = 1.5;

void main()	{
	if( ghost_sys.x >= 0.0 )	{
		s_light = Spatial( vec4(ghost_pos,1.0), vec4(0.0) );
		vec3 v = ghost_pos + extra * halo_data.x * at_vertex.xyz;
		vec3 vc = trans_inv(v,s_cam);
		gl_Position = get_projection(vc, proj_cam);
	}else	gl_Position = vec4(0.0,0.0,-2.0,1.0);
}
