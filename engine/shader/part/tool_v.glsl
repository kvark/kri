#version 130

uniform vec4 cur_time;
uniform float part_total;

out	vec2 to_sys;


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