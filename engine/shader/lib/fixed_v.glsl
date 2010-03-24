#version 130
precision lowp float;

in vec3 at_vertex;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

//fixed transform: camera space
vec3 fixed_trans(Spatial s_cam)	{
	vec3 v = trans_for(at_vertex, s_model);
	return trans_inv(v, s_cam);
}

//fixed transform: screen space
vec4 fixed_proj(Spatial sp, vec4 proj)	{
	vec3 v = fixed_trans(sp);
	return get_projection(v, proj);
}
