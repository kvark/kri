#version 130
//#define INT

uniform vec4 fur_init;

out vec3 to_prev,to_base;

vec3 qrot(vec4,vec3);

vec3 random_dir()	{
	float w = gl_VertexID;
	vec3 off = vec3(0.121,1.351,3.415);
	vec3 v = (vec3(w) + off) * vec3(1.0,2.0,3.0);
	v = fract( sin(78.233*v ) * 43758.5453 );
	return v;	//no normalizing
}


void set_base(vec4 vert, vec4 quat)	{
	vec3 dir = fur_init.xyz + fur_init.w * random_dir();
	to_base = vert.xyz;
	to_prev = to_base - qrot( quat*2.0-vec4(1.0),
		dir * vec3(vert.w,1.0,1.0) );
}
