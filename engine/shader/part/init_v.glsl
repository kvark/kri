#version 130
precision lowp float;

uniform float k_total;

out	vec2 to_sys;

void init();

void main()	{
	float r = gl_VertexID * k_total;
	to_sys = vec2(-1.0,r);
	init();
}
