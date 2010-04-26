#version 130

uniform vec4 cur_time;

float reset();
float update();
bool born_ready();


void main()	{
	if(born_ready() && update()<0.5)
		reset();
}
