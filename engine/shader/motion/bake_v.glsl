#version 130

in vec4 at_vertex;
out vec4 to_old, to_new;


uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_model,s_old_cam,s_old_mod;
uniform vec4 proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

vec4 result(Spatial sm, Spatial sc)	{
	vec3 w = trans_for(at_vertex.xyz, sm);
	vec3 c = trans_inv(w, sc);
	return get_projection(c,proj_cam);
}


void main()	{
	to_old = result(s_old_mod, s_old_cam);
	to_new = result(s_model, s_cam);
	gl_Position = to_new;
}