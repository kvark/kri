#version 130
precision lowp float;

in vec4 at_vertex;

vec3 mi_orco()	{
	//That's rough: an actual ORCO implementation is unknown
	return at_vertex.xyz;
}
