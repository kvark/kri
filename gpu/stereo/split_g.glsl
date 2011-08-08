#version 150 core

layout(triangles) in;
layout(triangle_strip, max_vertices=6) out;

in	vec4	pl[],pc[],pr[];
out	vec4	center, mask;


void emit_poly(vec4 coord[3], vec4 m)	{
	mask = m;
	for(int i=0; i<3; ++i)	{
		center = pc[i];
		gl_Position = coord[i];
		EmitVertex();
	}
	EndPrimitive();
}


void main()	{
	emit_poly( pl, vec4(1.0,0.5,0.0,0.5) );
	emit_poly( pr, vec4(0.0,0.5,1.0,0.5) );
}