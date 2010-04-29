#version 130

//(size,life)
in	vec2 at_sub;
in	vec3 at_pos, at_speed;
out	vec2 to_sub;
out	vec3 to_pos, to_speed;


uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

uniform vec4 part_speed_tan;	//w == tangental rotation
uniform vec4 part_speed_obj;	//w == ?
uniform vec4 object_speed;	//pre-multiplied already
uniform vec4 part_life;		//x +- y
const vec4 part_size	= vec4(0.0);	// x +- y

vec4 part_time();
float part_uni();
float random(float);
Spatial get_surface(vec2);
vec3 qrot(vec4,vec3);


void init_main()	{
	to_sub = vec2(0.0);
	to_speed = to_pos = vec3(0.0);
}

float reset_main()	{
	vec4 pt = part_time();
	float uni = part_uni(), rand = random(uni + pt.x),
		rs1 = 2.0*(rand-0.5), r2 = random(rand + pt.x+pt.z);
	vec4 sub = vec4(part_size.xy, part_life.xy);
	to_sub = sub.xz * (vec2(1.0) + rs1 * sub.yw);
	Spatial surf = get_surface( vec2(rand,r2) );	//todo: random
	to_pos = surf.pos.xyz;
	vec3 hand = vec3( surf.pos.w, 1.0,1.0);
	to_speed = object_speed.xyz + //add random
		qrot( surf.rot, hand *	part_speed_tan.xyz )  +
		qrot( s_model.rot,	part_speed_obj.xyz );
	return step(0.01, dot(to_pos,to_pos) );
}

float update_main()	{
	vec4 pt = part_time();
	to_sub = at_sub;
	to_pos = at_pos + pt.x * at_speed;
	to_speed = at_speed;
	return step( pt.y, at_sub.y );
}
