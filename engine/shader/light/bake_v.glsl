#version 130
precision lowp float;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 proj_lit, lit_data, range_lit;

vec3 fixed_trans(Spatial);
vec4 get_projection(vec3,vec4);

out float depth;

void main()	{
	vec3 v = fixed_trans(s_lit);
	depth = (v.z + range_lit.x) * range_lit.y;
	vec4 pos = get_projection(v, proj_lit);
	gl_Position = vec4(pos.xyz, mix(1.0, pos.w, lit_data.y));
}