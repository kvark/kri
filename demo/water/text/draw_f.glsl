#version 130

uniform sampler2D unit_wave;

noperspective in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = texture(unit_wave, tex_coord);
}
