#version 130

uniform vec4 halo_data, cur_time, part_child;

in vec2 at_sys;
in vec3 at_pos, at_speed;
out vec2 part_age;

void make_tex_coords();
void part_draw(vec3,float);
float random(float);
vec3 random_cube(float);

vec3 get_offset()	{
	vec3 cube = random_cube(gl_InstanceID);
	return part_child.x * (2.0*cube - vec3(1.0));
}


void main()	{
	make_tex_coords();
	gl_ClipDistance[0] = at_sys.x;
	part_age = vec2( cur_time.y - at_sys.x, gl_VertexID );
	float r0 = random(0.1432*gl_InstanceID + gl_VertexID)*2.0-1.0;
	float size = dot(part_child.zw, vec2(1.0,r0));
	vec3 off = cross( normalize(at_speed), get_offset() );
	part_draw( at_pos + off, halo_data.x * size );
}