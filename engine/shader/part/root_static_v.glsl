#version 130

in	vec2 at_sys;
out	vec2 to_sys;


float update();

void main()	{
	to_sys = at_sys;
	if(at_sys.x > 0.0)
		update();
}