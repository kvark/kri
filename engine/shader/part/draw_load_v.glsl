#version 130

in vec4 at_pos;

void part_draw(vec4);

void main()	{
	part_draw(at_pos);
}