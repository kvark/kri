#version 150

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_lit;
uniform vec4 proj_cam, proj_lit, screen_size;


vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

vec4 project(vec3 v, Spatial spa, vec4 pr)	{
	return get_projection( trans_inv(v,spa), pr);
}
void save_all(vec3 v, out vec4 vcam, out vec4 vlit)	{
	vcam = project(v, s_cam, proj_cam);
	vlit = project(v, s_lit, proj_lit);
}

in vec3 at_prev, at_base, at_pos;
out vec4 va,vb,vc;
out vec4 la,lb,lc;
out vec3 v0,v1,v2;


void main()	{
	float live = dot(at_base,at_base);
	gl_ClipDistance[0] = step(0.01,live)-0.5;
	v0 = at_prev; v1 = at_base; v2 = at_pos;

	save_all(at_prev,va,la);
	save_all(at_base,vb,lb);
	save_all(at_pos,vc,lc);
}
