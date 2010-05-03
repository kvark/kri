#version 130

uniform vec4 screen_size;
uniform sampler2DRect unit_input;

noperspective in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = texture2DRect(unit_input, tex_coord * screen_size.xy);
}
