#version 130

in vec3 at_sys;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam, screen_size;

vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

void part_draw(vec4 pos)	{	//W == size
	gl_ClipDistance[0] = at_sys.x;
	vec3 v = trans_inv(pos.xyz, s_cam);
	gl_Position = get_projection(v,proj_cam);
	gl_PointSize = pos.w * screen_size.z / (s_cam.pos.w * gl_Position.w);
}