#version 130
precision lowp float;

in	vec2 at_sys;
out	vec2 to_sys;

uniform vec4 cur_time;
uniform float part_total;

vec3 part_time()	{
	// global time, life time, frame time
	return vec3(cur_time.x, cur_time.x - at_sys.x, cur_time.y);
}
float part_uni()	{
	return at_sys.y * part_total;
}

void reset();
float update();
bool born_ready();

void main()	{
	to_sys = at_sys;
	if(at_sys.x > 0.0)	{
		float live = update();
		to_sys.x = 2.0*live-1.0;
	}else if( born_ready() )	{
		reset();
		to_sys.x = cur_time.x;
	}
}