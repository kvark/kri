#version 130

uniform vec4 part_life;

vec3 part_time();
vec2 part_uni();


bool born_ready()	{
	vec3 t = part_time();
	vec2 u = part_uni();
	float moment = mix( part_life.z, part_life.w, u.x );
	return t.z>moment && u.y==0.0;
}
