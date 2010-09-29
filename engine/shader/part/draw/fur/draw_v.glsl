#version 150

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam, screen_size;


vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

vec4 project(vec3 v)	{
	return get_projection( trans_inv(v,s_cam), proj_cam);
}

in vec3 at_prev, at_base, at_pos;
out vec4 va,vb,vc;


void main()	{
	float live = dot(at_base,at_base);
	gl_ClipDistance[0] = step(0.01,live)-0.5;
	
	va = project(at_prev);
	vb = project(at_base);
	vc = project(at_pos);
}
