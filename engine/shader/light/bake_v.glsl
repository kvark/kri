#version 130
precision lowp float;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 proj_lit, lit_data;

vec4 fixed_proj(Spatial,vec4);

void main()	{
	vec4 pos = fixed_proj(s_lit, proj_lit);
	gl_Position = vec4(pos.xyz, mix(1.0, pos.w, lit_data.y));
}