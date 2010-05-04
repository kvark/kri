#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;

void make_tex_coords();
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

in vec2 at_part_sys, at_part_sub;
in vec3 at_part_pos;
in vec4 at_vertex,at_quat;


void main()	{
	if( at_part_sys.x >= 0.0 )	{
		make_tex_coords();
		//todo: include particle rotation
		vec3 v = at_part_pos + at_vertex.xyz * at_part_sub.x;
		vec3 vc = trans_inv(v, s_cam);
		gl_Position = get_projection(vc, proj_cam);
	}else	gl_Position = vec4(0.0,0.0,-2.0,1.0);
}
