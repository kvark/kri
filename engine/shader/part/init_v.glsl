#version 130

out	vec3 to_sys;

void init();

void main()	{
	//bug: uniforms are not supported when the shader access gl_VertexID
	//temp solution: scale ID in the root shader, not here
	float r = float(gl_VertexID);
	to_sys = vec3(-1.0, r, 0.0);
	init();
}
