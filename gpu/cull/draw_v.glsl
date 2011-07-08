#version 150 core

in	vec4	at_pos, at_rot;
in	vec4	at_low, at_hai;

struct	Bound	{
	vec4 pos, rot;
	vec4 low, hai;
};
out	Bound	b;


void main()	{
	b = Bound( at_pos, at_rot, at_low, -at_hai );
}
