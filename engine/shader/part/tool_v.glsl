#version 130

uniform float part_total;

float part_uni()	{
	return gl_VertexID * part_total;
}
float random(float seed)	{
	return fract(sin( 78.233*seed ) * 43758.5453);
}
