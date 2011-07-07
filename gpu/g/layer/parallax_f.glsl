#version 130

uniform sampler2D	unit_bump;
uniform	float		parallax;
uniform int		has_data;
uniform vec4		screen_size;

in	vec3	view;
in	vec4	var_quat;
in	vec3	var_normal;

vec4	qinv2(vec4);
vec3	qrot2(vec4,vec3);


vec2 make_offset(vec2 tc)	{
	if(parallax == 0.0)	return tc;
	vec2 tscreen = gl_FragCoord.xy / screen_size.xy;
	vec4 bump = 2.0*texture( unit_bump, tscreen ) - vec4(1.0);
	vec3 bt = bump.xyz;
	vec3 vt = normalize(view);
	if((has_data & 4) != 0)	{
		vec4 q = qinv2( normalize(var_quat) );
		bt = qrot2(q,bt);
		vt = qrot2(q,vt);
	}else
	if((has_data & 2) != 0)	{	//normal
		vec3 pdx = dFdx(-view);
		vec3 pdy = dFdy(-view);
		vec2 tdx = dFdx(tc);
		vec2 tdy = dFdy(tc);
		vec3 t = normalize( tdy.y * pdx - tdx.y * pdy );
		vec3 b = normalize( tdy.x * pdx - tdx.x * pdy );
		vec3 n = normalize( var_normal );
		t = cross(b,n); b = cross(n,t);
		mat3 t2w = mat3(t,b,n);
		bt = bt * t2w;
		vt = vt * t2w;
	}else bump.w = 0.0;
	vec2 offset = parallax * bump.w * bt.z * vt.xy;
	return tc + offset;
}
