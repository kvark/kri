#version 130
const float size = 0.1;

in vec3 at_pos;

void part_draw(vec3,float);

void main()	{
	part_draw(at_pos,size);
}