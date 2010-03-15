#version 140
precision lowp float;

in	vec3 at_pos;
out	vec3 to_pos;
in	vec3 at_speed;
out	vec3 to_speed;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;
uniform vec4 cur_time;

vec3 qrot(vec4,vec3);

void init_simple()	{
	to_speed = to_pos = vec3(0.0);
}

void reset_simple()	{
	to_pos = s_model.pos.xyz;
	to_speed = qrot(s_model.rot, vec3(0.0,0.0,1.0));
}

float update_simple()	{
	to_speed = at_speed;
	to_pos = at_pos + cur_time.y * at_speed;
	return step(dot(to_pos,to_pos), 5.0);
}
