#version 130

//pos.w == size; speed.w == life
in	vec4 at_pos, at_speed;
out	vec4 to_pos, to_speed;


uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

uniform vec4 part_speed_tan;	//w == tangental rotation
uniform vec4 part_speed_obj;	//w == ?
uniform vec4 object_speed;	//pre-multiplied already
uniform vec4 part_life;		//x +- y
uniform vec4 part_force;	//brownian, drag, damp
uniform vec4 part_size;		//x +- y
uniform vec4 force_world;	//gravity + wind + ...


vec3 part_time();
vec2 part_uni();
float random(float);
Spatial get_surface(vec2);
vec3 qrot(vec4,vec3);


void init_load()	{
	to_speed = to_pos = vec4(0.0);
}

void reset_load()	{
	vec3 pt = part_time();
	float uni = part_uni().x, rand = random(uni + pt.x),
		rs1 = 2.0*(rand-0.5), r2 = random(rand + pt.x+pt.z);
	float life = part_life.x + rs1 * part_life.y;
	float size = part_size.x + rs1 * part_size.y;
	Spatial surf = get_surface( vec2(rand,r2) );	//todo: random
	to_pos = vec4( surf.pos.xyz, size );
	vec3 hand = vec3( surf.pos.w, 1.0,1.0);
	to_speed.xyz = object_speed.xyz + //add random
		qrot( surf.rot, hand *	part_speed_tan.xyz )  +
		qrot( s_model.rot,	part_speed_obj.xyz );
	to_speed.w = life;
}

float update_load()	{
	vec3 t = part_time();
	to_pos = at_pos + t.x * vec4( at_speed.xyz, 0.0 );
	to_speed = at_speed + t.x * vec4( force_world.xyz, 0.0 );
	return step( t.y, at_speed.w );
}
