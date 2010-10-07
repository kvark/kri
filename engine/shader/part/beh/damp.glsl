#version 130
//proven to be frame-independent

uniform vec4 cur_time;
uniform float speed_damp;

out	vec3 to_speed;

const float kt = -2.0;

float update_damp()	{
	to_speed *= exp( kt*speed_damp*cur_time.x );
	return 1.0;
}
