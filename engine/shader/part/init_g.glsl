#version 140
#extension GL_EXT_geometry_shader4 : require

//in	vec2 to_xxx[1];
out	vec2 to_sys;
out	vec3 to_pos;
out	vec3 to_speed;

//uniform vec4 cur_time;
//uniform int number;

void main()	{
	to_sys = vec2(-1.0,0.0);
	to_pos = to_speed = vec3(0.0);
	for(int i=0; i<1; ++i)	{
		to_sys.y = float(i);
		EmitVertex();
		EndPrimitive();
	}
}