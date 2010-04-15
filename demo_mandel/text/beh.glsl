#version 130

in	vec4 at_pos;
out	vec4 to_pos;

uniform float limit;

vec3 part_time();
vec2 part_uni();
float random(float);

void init_mand()	{
	to_pos = vec4(0.0);
}

float reset_mand()	{
	vec3 pt = part_time();
	float uni = part_uni().x;
	float x = random(uni+pt.y*pt.x), y = random(x+pt.z*pt.x);
	to_pos = 2.0*vec4(x,y,x,y) - vec4(1.0);
	return 1.0;
}

float update_mand()	{
	vec2 p = at_pos.xy;
	vec2 p2 = vec2(p.x*p.x-p.y*p.y, 2.0*p.x*p.y) + at_pos.zw;
	to_pos = vec4(p2, at_pos.zw);
	float lim = step( part_time().y, limit );
	return step(dot(p2,p2), 4.0) * lim;
}
