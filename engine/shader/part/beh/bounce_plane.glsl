#version 130

out	vec3 to_pos,to_speed;

uniform vec4 coord_plane;
uniform float reflect_koef;

float update_bounce()	{
	float d = dot( coord_plane, vec4(to_pos,1.0) );
	float ref = mix( reflect_koef, -1.0, step(0.0,d) );
	to_speed -= (1.0+ref) *coord_plane.xyz* to_pos;
	return 1.0;
}
