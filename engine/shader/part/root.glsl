#version 140
precision lowp float;

in	vec2 at_sys;
out	vec2 to_sys;

uniform vec4 cur_time;

void reset();
float update();
bool born_ready();

void main()	{
	to_sys = at_sys;
	if(at_sys.x > 0.0)	{
		float live = update();
		to_sys.x *= 2.0*live-1.0;
	}else if( born_ready() )	{
		reset();
		to_sys.x = cur_time.x;
	}
}