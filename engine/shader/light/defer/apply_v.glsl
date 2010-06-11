#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_model;
uniform vec4 proj_cam;

vec4 fixed_proj(Spatial,vec4);
vec4 qinv(vec4);
vec4 qmul(vec4,vec4);
void make_tex_coords();

in vec4 at_quat;
out vec2 tc;
out vec4 tan2cam;


void main()	{
	make_tex_coords();
	
	gl_Position = fixed_proj(s_cam, proj_cam);
	tc = (gl_Position.xy / gl_Position.w)*0.5 + vec2(0.5);

	vec4 tan2w = qmul(s_model.rot, at_quat);
	tan2cam = qmul( qinv(s_cam.rot), tan2w );
}