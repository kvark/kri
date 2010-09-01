#version 130
//"Position Based Dynamics"
//by AGEIA, VRIPHYS 2006

uniform vec4 cur_time;

in	vec3 at_base;
in	vec3 at_pos, at_speed;
out	vec3 to_pos, to_speed;

float update();


void main()	{
	to_pos = at_pos;
	to_speed = at_speed;
	if( dot(at_base,at_base) < 0.01 ) return;
	vec3 old = at_pos;
	update();
	to_speed = (to_pos-old) / max(0.001,cur_time.x);
}
