#version 130

uniform sampler2DArray	unit_gbuf;

in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = vec4(0.0,0.0,0.0,1.0);
}