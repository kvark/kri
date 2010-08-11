#version 130

uniform sampler2D unit_wave;

noperspective in vec2 tex_coord;
out float wave;

void main()	{
	wave = texture(unit_wave, tex_coord).x;
}
