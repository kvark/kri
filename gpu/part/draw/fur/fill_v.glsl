#version 150 core

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit;
uniform vec4 proj_lit, lit_data, range_lit;

vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


in	vec3 at_base, at_pos;
out	vec4 vb,vc;
out	vec3 dep;


void main()	{ vec3 p;
	dep.z = dot(at_base,at_base);

	p = trans_inv(at_base,s_lit);
	dep.x = (p.z + range_lit.x) * range_lit.z;
	vb = get_projection(p,proj_lit);

	p = trans_inv(at_pos,s_lit);
	dep.y = (p.z + range_lit.x) * range_lit.z;
	vc = get_projection(p,proj_lit);
}