#version 140

in	vec3 at_vertex;
in	vec4 at_quat;
in	vec3 at_tex;
out	vec3 to_vert;
out	vec4 to_quat;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

vec3 trans_for(vec3,Spatial);
vec4 qmul(vec4,vec4);

void main()	{
	//encoding handness bit into pos.w
	to_vert = vec4( trans_for(at_vertex, s_model), at_tex.z );
	to_quat = qmul(s_model.rot, at_quat);
	gl_Position = vec4(at_tex.xy, 0.0,1.0);
}