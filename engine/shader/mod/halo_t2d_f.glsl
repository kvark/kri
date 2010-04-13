#version 130

uniform vec4 halo_color;
uniform sampler2D unit_halo;

vec4 get_diffuse()	{
	return halo_color * texture(unit_halo, gl_PointCoord);
}