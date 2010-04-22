#version 130

in vec2 at_sys;
in vec4 at_pos;
out float time;

uniform float size;
uniform vec4 cur_time;


void main()	{
	gl_ClipDistance[0] = at_sys.x;
	time = cur_time.x  - at_sys.x;
	gl_PointSize = size;
	gl_Position = vec4(at_pos.xy, 0.0,1.0);
}