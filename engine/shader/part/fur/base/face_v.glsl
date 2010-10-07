#version 130
//#define INT
#define FILTER

uniform sampler2D unit_vert, unit_quat;
uniform int width;

void set_base(vec4,vec4);
vec3 random_dir(float);

const float factor_jitter	= 0.9;

vec2 rand_off()	{
	return mix( vec2(0.5), random_dir(2.423).xy, factor_jitter );
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
	vec2 tc = vec2(cx,cy);
	float dw = 1.0 / width;
	vec2 t0 = dw * (tc + vec2(0.5));
	vec4 vert = texture(unit_vert,t0);
	#ifdef FILTER
	vec2 t1 = dw * (tc + rand_off());
	vec4 v0=vert, v1=texture(unit_vert,t1);
	float diff = v0.w - v1.w;
	vert = mix( v1,v0, step(0.1,diff*diff) );
	vert.w = sign( v0.w );
	#endif
	vec4 quat = texture(unit_quat,t0);
	#endif
	set_base(vert,quat);
}
