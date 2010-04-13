#version 130
const float size = 0.1;

in vec3 at_pos;

void part_draw(vec4);

void main()	{
	part_draw(vec4( at_pos, size ));
}