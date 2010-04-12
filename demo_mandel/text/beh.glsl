#version 130

in	vec4 at_pos;
out	vec4 to_pos;

uniform float root,limit;

vec3 part_time();
vec2 part_uni();

void init_mand()	{
	to_pos = vec4(0.0);
}

void reset_mand()	{
	float uni = part_uni().x;
	float y = trunc(uni*root)/root, x = root*(uni-y);
	to_pos = 2.0*vec4(x,y,x,y) - vec4(1.0);
}

float update_mand()	{
	vec2 p = at_pos.xy;
	vec2 p2 = vec2(p.x*p.x-p.y*p.y, 2.0*p.x*p.y) + at_pos.zw;
	to_pos = vec4(p2, at_pos.zw);
	float lim = step( part_time().y, limit );
	return step(dot(p2,p2), 4.0) * lim;
}
