#version 130

uniform vec4 part_life;

vec4 part_time();
float part_uni();


bool born_ready()	{
	vec4 t = part_time();
	float u = part_uni();
	//return all(lessThan( t.zw, vec2(1.0-u,1.0) * part_life.zw ));
	return t.z>u*part_life.z && t.w<part_life.w;
}
