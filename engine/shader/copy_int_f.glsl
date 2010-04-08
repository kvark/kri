#version 130

uniform usampler2D unit_input;
in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = vec4(texture(unit_input, tex_coord).r);
}
