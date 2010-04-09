#version 130

in	vec2 at_p,at_c;
out	vec2 to_p,to_c;

uniform float root,limit;

vec3 part_time();
float part_uni();

void init_mand()	{
	to_p = to_c = vec2(0.0);
}

void reset_mand()	{
	float uni = part_uni();
	float y = trunc(uni*root)/root, x = root*(uni-y);
	to_p = to_c = 2.0*vec2(x,y) - vec2(1.0);
}

float update_mand()	{
	to_c = at_c; vec2 p = at_p;
	to_p = at_c + vec2(p.x*p.x-p.y*p.y, 2.0*p.x*p.y);
	//to_p = at_c;
	float lim = step( part_time().y, limit );
	return step(dot(to_p,to_p), 4.0) * lim;
}
