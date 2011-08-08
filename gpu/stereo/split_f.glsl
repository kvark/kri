#version 130

uniform	sampler2D	unit_color;

in	vec4	center, mask;
out	vec4	rez_color;

void main()	{
	//make sure it will be normalized into [0,1]
	vec3 corrected = center.xyw + center.www;
	vec4 color = textureProj(unit_color, corrected);
	rez_color = color * mask;
}
