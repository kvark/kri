#version 130

uniform float size;

in vec4 at_pos;
out float time;


void main()	{
	gl_ClipDistance[0] = 1.0;
	time = 100.0;
	gl_PointSize = size;
	gl_Position = vec4(at_pos.xy, 0.0,1.0);
	gl_Position = vec4(0.0,0.0,0.0,1.0);
	gl_PointSize = 10.0;
}