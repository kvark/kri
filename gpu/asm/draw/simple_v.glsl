#version 130

in	vec4	at_vertex;
in	vec4	at_quat;
in	vec4	at_tex;
in	int	at_index;

struct Spatial	{
	vec4 pos,rot;
};

uniform	Spatial	s_cam, s_lit;

struct Element	{
	Spatial	spa;
	vec4	area;
	int	channel;
};

const	int	NE	= 50;
uniform	Element el[NE];

uniform	vec4 proj_cam;

vec3 qrot(vec4,vec3);
vec4 qmul(vec4,vec4);
vec4 qinv(vec4);
vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


out	vec3	v_lit;


void main()	{
	vec3 v = at_vertex.xyz;
	vec3 vw = trans_for( v, el[at_index].spa );
	v = trans_inv( vw, s_cam );
	gl_Position = get_projection( v, proj_cam );
	vec4 q = qinv(qmul( el[at_index].spa.rot, at_quat ));
	v_lit = vec3(at_vertex.w,1.0,1.0) * qrot(q, s_lit.pos.xyz - vw);
}
