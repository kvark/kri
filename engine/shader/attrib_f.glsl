#version 130

in vec4 color;
out vec4 rez_color;

void main()	{
	rez_color = normalize(color);
}
