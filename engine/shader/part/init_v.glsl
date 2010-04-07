#version 130
precision lowp float;

out	vec2 to_sys;

void init();

void main()	{
	//bug: uniforms are not supported when the shader access gl_VertexID
	//temp solution: scale ID in the root shader, not here
	float r = float(gl_VertexID);
	to_sys = vec2(-1.0,r);
	init();
}
