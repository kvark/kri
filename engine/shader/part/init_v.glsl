#version 140
precision lowp float;

in	vec2 at_sys;
out	vec2 to_sys;

void init();

void main()	{
	float r = float(gl_VertexID);
	to_sys = vec2(-1.0,r);
	init();
}


/*
in	vec2 at_sys;
in	vec2 at_pos;
in	vec2 at_speed;
out	vec2 to_xxx;

void main()	{
	to_xxx = vec2(-1.0,0.0);
}*/
