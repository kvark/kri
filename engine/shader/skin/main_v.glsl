#version 130

out	vec4 to_vertex,to_quat;

struct Spatial	{
	vec4 pos,rot;
};

Spatial append_all();
void finish(vec3);

void main()	{
	//to_vertex = at_vertex; to_quat = at_quat; return;
	Spatial sp = append_all();
	to_vertex = sp.pos;
	to_quat = sp.rot;
	finish( to_vertex.xyz );
}