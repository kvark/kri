#version 130

in	vec4	at_vertex;
in	vec4	at_quat;
in	vec4	at_tex;
in	int	at_index;

struct Spatial	{
	vec4 pos,rot;
};

uniform	Spatial	s_cam;

struct Element	{
	Spatial	spa;
	vec4	area;
	int	channel;
};

const	int	NE	= 50;
uniform	Element el[NE];

uniform	vec4 proj_cam;

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


void main()	{
	vec3 v = at_vertex.xyz;
	v = trans_for( v, el[at_index].spa );
	v = trans_inv( v, s_cam );
	gl_Position = get_projection( v, proj_cam );
}
