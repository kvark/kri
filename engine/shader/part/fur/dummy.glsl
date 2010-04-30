#version 130

out vec2 to_sys;

void init_dummy()	{
	to_sys = vec2(0.0);
}

float reset_dummy()	{
	to_sys = vec2(2.0);
	return 1.0;
}

float update_dummy()	{
	to_sys = vec2(1.0);
	return 1.0;
}