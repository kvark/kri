#version 150 core

layout(points)	in;
layout(line_strip, max_vertices=2) out;


in	vec4	pos[], rot[], par[];
out	vec4	color;


void main()	{
	color = vec4(1.0);
	gl_Position = par[0];
	EmitVertex();
	gl_Position = pos[0];
	EmitVertex();
	EndPrimitive();
}