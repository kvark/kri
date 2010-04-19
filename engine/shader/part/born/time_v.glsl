#version 130

uniform vec4 part_life;

vec4 part_time();
float part_uni();


bool born_ready()	{
	vec4 t = part_time();
	float u = part_uni();
	return all(greaterThan( t.zw, vec2(u,-1.0) * part_life.zw ));
}
