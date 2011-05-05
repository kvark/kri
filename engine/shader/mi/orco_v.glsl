#version 130

uniform	struct BBox	{
	vec4	center, hsize;
} bb_model;

in vec4 at_vertex;

vec3 mi_orco()	{
	return ((at_vertex - bb_model.center) / bb_model.hsize).xyz;
}
