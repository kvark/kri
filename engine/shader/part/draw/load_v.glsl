#version 130

uniform vec4 halo_data;

in vec2 at_sys;
in vec4 at_pos;

void part_draw(vec3,float);

void main()	{
	gl_ClipDistance[0] = at_sys.x;
	part_draw( at_pos.xyz, halo_data.x );
}