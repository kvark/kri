#version 130

//todo: Vertex array->TBO access here

struct Spatial	{ vec4 pos,rot; }
get_surface(vec2 tc)	{
	return Spatial( vec4(0.0), vec4(0.0) );
}