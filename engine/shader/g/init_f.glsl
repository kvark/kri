#version 130

uniform sampler2DArray	unit_gbuf;

noperspective in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	vec4 diff = texture( unit_gbuf, vec3(tex_coord,0.0) );
	rez_color = diff.w * diff;
}