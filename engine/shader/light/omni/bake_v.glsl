#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;

vec3 fixed_trans(Spatial);

void main()	{
	gl_Position = vec4( fixed_trans(s_lit), 0.0);
}
