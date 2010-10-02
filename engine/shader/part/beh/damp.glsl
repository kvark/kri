#version 130

uniform vec4 cur_time;
uniform float speed_damp;

out	vec3 to_speed;

const float kt = 1.5;

float update_damp()	{
	to_speed *= max( 1.0 - kt*speed_damp*cur_time.x, 0.0);
	return 1.0;
}
