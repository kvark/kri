#version 130

in	vec3 at_base;
in	vec3 at_pos, at_speed;
out	vec3 to_pos, to_speed;


float update();

void main()	{
	to_pos = at_pos;
	to_speed = at_speed;
	if( dot(at_base,at_base) > 0.01 )
		update();
}
