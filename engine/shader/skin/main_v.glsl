#version 130

in	uvec4 at_skin;
out	vec4 to_vertex,to_quat;

const int NB = 80;
uniform struct Spatial	{
	vec4 pos,rot;
}bone[NB];

void append(float,Spatial);
Spatial result();
void finish(vec3);

void main()	{
	//to_vertex = at_vertex; to_quat = at_quat; return;
	uvec4 ids = at_skin >> uint(8);
	vec4 wes = vec4(at_skin & uvec4(255)) * (1.0/255.0);
	for(int i=0; i<4; ++i)
		append( wes[i], bone[int(ids[i])] );
	Spatial sp = result();
	to_vertex = sp.pos;
	to_quat = sp.rot;
	finish( to_vertex.xyz );
}