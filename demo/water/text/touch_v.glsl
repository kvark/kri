#version 130

uniform vec4 mouse_pos;

in float pos;

void main()	{
	gl_PointSize = 20.0;
	gl_Position = vec4( mouse_pos.xyz, 1.0 );
}