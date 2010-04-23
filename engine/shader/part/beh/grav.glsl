#version 130

uniform vec4 cur_time;
uniform vec4 force_world;	//gravity + wind + ...

out	vec3 to_speed;


float update_grav()	{
	to_speed += cur_time.y * force_world.xyz;
	return 1.0;
}
