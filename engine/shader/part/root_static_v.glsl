#version 130

in	vec3 at_base;

float update();
float reset();

void main()	{
	reset();
	if( dot(at_base,at_base) > 0.01 )
		update();
}