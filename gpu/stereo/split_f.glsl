#version 130

uniform	sampler2D	unit_color;

in	vec4	center, mask;
out	vec4	rez_color;

void main()	{
	vec3 corrected = center.xyw + vec3(center.ww,0.0);
	vec4 color = textureProj(unit_color, corrected);
	rez_color = color * mask;
}
