#version 130

uniform struct Spatial	{
	vec4	pos,rot;
}s_model,s_cam;

uniform vec4	proj_cam;


vec3 qrot(vec4,vec3);
vec4 fixed_proj(Spatial,vec4);

in	vec4	at_vertex;
in	vec3	at_normal;
out	vec4	normal;


void main()	{
	vec3 wn = qrot( s_model.rot, at_normal );
	normal = vec4( wn, at_vertex.w );
	gl_Position = fixed_proj(s_cam, proj_cam);
}
