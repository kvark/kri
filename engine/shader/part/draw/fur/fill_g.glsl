#version 150

layout(points) in;
layout(line_strip, max_vertices = 2) out;


in gl_PerVertex	{
	float gl_ClipDistance[];
}gl_in[];
in vec4 vb[],vc[];
in vec2 dep2[];

out gl_PerVertex	{
	vec4 gl_Position;
	float gl_ClipDistance[1];
};
out float depth;


void main()	{
	if(gl_in[0].gl_ClipDistance[0] < 0.0) return;
	gl_ClipDistance[0] = gl_in[0].gl_ClipDistance[0];
	depth = dep2[0].x;
	gl_Position = vb[0];
	EmitVertex();
	depth = dep2[0].y;
	gl_Position = vc[0];
	EmitVertex();
}