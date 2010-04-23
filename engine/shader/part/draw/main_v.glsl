#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam, screen_size;


vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


void part_draw(vec3 pos, float size)	{
	gl_Position = get_projection( trans_inv(pos, s_cam), proj_cam );
	gl_PointSize = 2.0*size * screen_size.z / (s_cam.pos.w * gl_Position.w);
}