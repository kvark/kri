#version 130

uniform vec4 halo_data;

in vec4 at_pos;

void part_draw(vec4);

void main()	{
	vec4 pos = at_pos;
	pos.w = 2.0 * halo_data.x;
	part_draw(pos);
}