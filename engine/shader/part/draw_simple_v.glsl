#version 130
precision lowp float;
const float size = 1.0;

in vec3 at_pos;

void part_draw(vec4);

void main()	{
	part_draw(vec4( at_pos, size ));
}