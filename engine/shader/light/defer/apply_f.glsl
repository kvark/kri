#version 130

uniform sampler2DArray unit_light;

// material data
vec4 get_bump();
vec4 get_diffuse();

// deferred funcs
vec3 qrot2(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
vec4 get_harmonics(vec3);


in vec2	tc;
in vec4 tan2cam;
out vec4 rez_color;


void main()	{
	vec4 ca = texture( unit_light, vec3(tc,0.0) ) - vec4(0.5);
	vec4 cb = texture( unit_light, vec3(tc,1.0) ) - vec4(0.5);
	vec4 cc = texture( unit_light, vec3(tc,2.0) ) - vec4(0.5);
	
	// camera space normal
	vec3 normal = qrot2( tan2cam, get_bump().xyz );
	vec4 kf = get_harmonics(normal);
	rez_color = vec4( dot(ca,kf), dot(cb,kf), dot(cc,kf), 1.0);
}