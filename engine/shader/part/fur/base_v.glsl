#version 130
//#define INT

uniform sampler2D unit_vert, unit_quat;
uniform int width;
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


void main()	{
	#ifdef INT
	int yc = gl_VertexID / width;
	ivec2 tc = ivec2(gl_VertexID - yc*width, yc);
	vec4 vert = texelFetch(unit_vert,tc,0);
	vec4 quat = texelFetch(unit_quat,tc,0);
	#else
	int cy = gl_VertexID / width,
		cx = gl_VertexID - cy*width;
	float dw = 1.0 / width;
	vec2 tc = (ivec2(cx,cy) + vec2(0.5)) * dw;
	vec4 vert = texture(unit_vert,tc);
	vec4 quat = texture(unit_quat,tc);
	#endif
	vec3 dir = fur_init.xyz + fur_init.w * random_dir();
	to_base = vert.xyz;
	to_prev = to_base - qrot( quat*2.0-vec4(1.0),
		dir * vec3(vert.w,1.0,1.0) );
}
