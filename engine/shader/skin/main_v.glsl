#version 130

out	vec4 to_vertex,to_quat;

struct Spatial	{
	vec4 pos,rot;
};

void append_all();
Spatial result();
void finish(vec3);

void main()	{
	//to_vertex = at_vertex; to_quat = at_quat; return;
	append_all();
	Spatial sp = result();
	to_vertex = sp.pos;
	to_quat = sp.rot;
	finish( to_vertex.xyz );
}