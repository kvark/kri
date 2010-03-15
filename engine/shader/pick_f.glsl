#version 130
precision lowp float;

uniform int index;
out uvec4 out_index;

void main()	{
	out_index = uvec4(index);
}
