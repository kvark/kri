#version 130
precision lowp float;

in	vec3 at_pos;
out	vec3 to_pos;
in	vec3 at_speed;
out	vec3 to_speed;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

vec3 part_time();
float part_sign();
vec3 qrot(vec4,vec3);

void init_simple()	{
	to_speed = to_pos = vec3(0.0);
}

void reset_simple()	{
	to_pos = s_model.pos.xyz;
	float r = part_sign();
	vec3 dir = normalize(vec3( r-0.5, 1.0, 0.0 ));
	to_speed = (1.0 + r) * qrot(s_model.rot, dir);
}

float update_simple()	{
	float delta = part_time().z;
	to_speed = at_speed;
	to_pos = at_pos + delta * at_speed;
	vec3 diff = to_pos - s_model.pos.xyz;
	return step(dot(diff,diff), 10.0);
}
