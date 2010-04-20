#version 130

in	vec2 at_sys;
out	vec2 to_sys;

uniform vec4 cur_time;
uniform float part_total;

vec4 part_time()	{
	// frame time, life time, global time, -number of lifes
	return vec4(cur_time.y, cur_time.x - to_sys.x, cur_time.x, to_sys.y);
}
float part_uni()	{
	return gl_VertexID * part_total;
}
float random(float seed)	{
	return fract(sin( 78.233*seed ) * 43758.5453);
}

float reset();
float update();
bool born_ready();

void main()	{
	to_sys = at_sys;
	float live = 1.0;
	if(at_sys.x > 0.0)
		live = update();
	else if( born_ready() )	{
		to_sys.x = cur_time.x;
		to_sys.y -= 1.0;
		live = reset();
	}
	to_sys.x *= 2.0*live-1.0;
}