#version 150 core
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in gl_PerVertex	{
	vec4 gl_Position;
}gl_in[];

in vec4 tog_vertex[], tog_quat[];
out vec4 to_vertex, to_quat;


void main()	{
	for(int i=0; i<gl_in.length(); i++)	{
		to_vertex	= tog_vertex[i];
		to_quat		= tog_quat[i];
		to_vertex.w *= 1.0 + gl_PrimitiveIDIn;
		gl_Position	= gl_in[i].gl_Position;
		EmitVertex();
	}
	EndPrimitive();
}
