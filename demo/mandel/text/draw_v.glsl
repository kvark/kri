#version 130

uniform float size;

in vec4 at_pos;
in float at_sys;
out float time;


void main()	{
	gl_ClipDistance[0] = 1.0;
	time = at_sys;
	gl_PointSize = size;
	gl_Position = vec4(at_pos.xy, 0.0,1.0);
}