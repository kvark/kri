#version 130

uniform	vec4		proj_cam;
uniform	float		half_eye, focus_dist;

uniform struct Spatial	{
	vec4 pos,rot;
}s_view;


in	vec4	at_vertex;
out	vec4	pl,pc,pr;

vec3	trans_for(vec3,Spatial);
vec4	get_projection(vec3,vec4);


void main()	{
	vec3 vc = trans_for( at_vertex.xyz, s_view );
	vec3 off = vec3(0.0);
	off.x = (focus_dist - vc.z) * half_eye / vc.z;
	pc = gl_Position = get_projection(vc,proj_cam);
	pl = get_projection(vc-off,proj_cam);
	pr = get_projection(vc+off,proj_cam);
}