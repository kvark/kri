#version 130

uniform sampler2D unit_input;

in	vec4	at_pos, at_rot;
in	vec4	at_low, at_hai;
out	bool	to_visible;


vec4 bound_sphere()	{
	vec3 center	= 0.5*(at_low.xyz + at_hai.xyz);
	vec3 d		= 0.5*(at_hai.xyz - at_low.xyz);
	float radius = max( d.z, max(d.x,d.y) );
	return vec4(center,radius) * at_pos.w + vec4(at_pos.xyz,0.0);
}


void main()	{
	vec4 sphere = bound_sphere();
	to_visible = true;
}
