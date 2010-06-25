#version 130

uniform vec4 base_color;

vec4 get_emissive();

out vec4 rez_color;

void main()	{
	rez_color = base_color + get_emissive();
}
