#version 130

uniform float object_id;

out vec4 rez_id;

void main()	{
	rez_id = vec4(object_id);
}