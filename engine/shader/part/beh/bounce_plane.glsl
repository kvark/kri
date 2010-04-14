#version 130

out	vec4 to_pos,to_speed;

uniform vec4 coord_plane;
uniform float reflect_koef;

float update_bounce_plane()	{
	float dp = dot( coord_plane, vec4(to_pos.xyz,1.0) );
	float ds = dot( coord_plane.xyz, to_speed.xyz );
	float bad = step(dp,0.0) * step(ds,0.0);
	float ref = mix( -1.0, reflect_koef, bad );
	to_speed.xyz -= (1.0+ref) *coord_plane.xyz* to_speed.xyz;
	return 1.0;
}
