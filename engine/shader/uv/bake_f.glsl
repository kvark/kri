#version 130

in	vec4 to_vertex, to_quat;
out	vec4 re_vertex, re_quat;

uniform float quat_scale;

void main()	{
	re_vertex = to_vertex;
	re_quat = to_quat * quat_scale;
}
