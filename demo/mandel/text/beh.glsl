#version 130

in	vec4 at_pos;
out	vec4 to_pos;

uniform vec4 cur_time;

float part_uni();
float random(float);


void init_mand()	{
	to_pos = vec4(5.0);
}

float reset_mand()	{
	//to_pos = vec4(0.0); return 1.0;
	float uni = part_uni();
	vec2 dt = cur_time.xy;
	float x = random(uni+dt.x*dt.y);
	vec2 v = vec2( x, random(x+dt.x+dt.y) );
	to_pos = 2.0*v.xyxy - vec4(1.0);
	return 1.0;
}

float update_mand()	{
	//to_pos = at_pos; return 1.0;
	vec2 p = at_pos.xy;
	vec2 p2 = vec2(p.x*p.x-p.y*p.y, 2.0*p.x*p.y) + at_pos.zw;
	to_pos = vec4(p2, at_pos.zw);
	return step(dot(p2,p2), 4.0);
}
