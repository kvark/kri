#version 130

in	uint	at_index;
out	uint	to_index;

uniform	uint	offset;


void main()	{
	to_index = offset + at_index;
}