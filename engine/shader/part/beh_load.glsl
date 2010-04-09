#version 130

//pos.w == life
in	vec4 at_pos, at_speed;
out	vec4 to_pos, to_speed;


uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

uniform vec4 part_speed_tan;	//w == tangental rotation
uniform vec4 part_speed_obj;	//w == ?
uniform vec4 object_speed;	//pre-multiplied already
uniform vec4 part_life;		//x +- y


vec3 part_time();
float part_uni();
Spatial get_surface(vec2);
vec3 qrot(vec4,vec3);


void init_load()	{
	to_speed = to_pos = vec4(0.0);
}

void reset_load()	{
	vec3 pt = part_time();
	float uni = part_uni(), rand = 0.0; //[-1,1]
	float life = part_life.x + rand * part_life.y;
	surf = get_surface( vec2(0.5,0.5) );	//todo: random
	to_pos = vec4(surf.pos.xyz, life);
	vec3 hand = vec3( surf.pos.w, 1.0,1.0);
	to_speed.xyz = object_speed.xyz + //add random
		qrot( surf.rot, hand *	part_speed_tan.xyz )  +
		qrot( s_model.rot,	part_speed_obj.xyz );
}

float update_load()	{
	vec3 pt = part_time();
	float delta = pt.z;
	to_speed = at_speed;
	to_pos = at_pos + delta * vec4( at_speed.xyz, 0.0 );
	return step(pt.y, at_pos.w);
}
