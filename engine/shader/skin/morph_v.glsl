#version 130

uniform vec4 shape_value;

in vec3 at_pos0;
in vec3 at_pos1;
out vec4 to_pos;


void main()	{
	to_pos = vec4(
		shape_value.x * at_pos0 +
		shape_value.y * at_pos1,
		1.0 );
}
