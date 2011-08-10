#version 150 core

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 lit_data, range_lit;

vec3 fixed_trans(Spatial);
vec4 get_proj_lit(vec3);

out float depth;

void main()	{
	vec3 v = fixed_trans(s_lit);
	depth = (v.z + range_lit.x) * range_lit.z;
	vec4 pos = get_proj_lit(v);
	gl_Position = vec4(pos.xyz, mix(1.0, pos.w, lit_data.y));
}