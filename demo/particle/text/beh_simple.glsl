#version 150 core

in	vec3 at_pos,at_speed;
out	vec2 to_sys;
out	vec3 to_pos,to_speed;

uniform sampler2D unit_vertex, unit_quat;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

vec4 part_time();
float part_uni();
float random(float);
vec3 qrot(vec4,vec3);

void init_simple()	{
	to_sys = vec2(-1.0,0.0);
	to_speed = to_pos = vec3(0.0);
}

float reset_simple()	{
	to_pos = s_model.pos.xyz;
	vec4 pt = part_time();
	float uni = part_uni(),
		r1 = random(uni), r2 = random(uni+pt.z);
	float a = r1 * 2.0*3.1416;
	vec3 dir = vec3( sin(a), cos(a), 0.0 );
	to_speed = (1.0 + 10.0*r2) * qrot(s_model.rot, dir);
	//new func
	vec4 pos = texture(unit_vertex, vec2(r1,r2));
	to_pos = pos.xyz;
	vec4 quat = 2.0*texture(unit_quat, vec2(r1,r2)) - vec4(1.0);
	to_speed = qrot(quat, vec3(0.0,0.0,1.0));
	to_speed.x *= pos.w;
	to_speed *= 2.0 + 3.0*r1;
	return 1.0;
}

float update_simple()	{
	float delta = part_time().x;
	to_speed = at_speed;
	to_pos = at_pos + delta * at_speed;
	vec3 diff = to_pos - s_model.pos.xyz;
	return step(dot(diff,diff), 100.0);
}
