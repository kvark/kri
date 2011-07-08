#version 140

layout(points) in;
layout(line_strip, max_vertices = 24) out;

struct Spatial	{ vec4 pos,rot; };

uniform	Spatial	s_cam;
uniform vec4	proj_cam;

struct	Bound	{
	vec4 pos, rot;
	vec4 low, hai;
};
in	Bound	b[];

Spatial s_model	= Spatial( b[0].pos, b[0].rot );


vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


//	transform local coordinate into camera NDC

vec4 to_screen(vec3 mask)	{
	vec3 v = mix( b[0].low.xyz, b[0].hai.xyz, mask );
	vec3 w = trans_for(v,s_model);
	vec3 c = trans_inv(w,s_cam);
	return get_projection(c,proj_cam);
}

void draw_line(vec4 x, vec4 y)	{
	gl_Position = x;
	EmitVertex();
	gl_Position = y;
	EmitVertex();
	EndPrimitive();
}


void main()	{
	//construct points
	const vec2 one = vec2(0.0,1.0);
	vec4 p[] = vec4[8]	(
		to_screen(one.xxx),	//0
		to_screen(one.xxy),	//1
		to_screen(one.xyx),	//2
		to_screen(one.xyy),	//3
		to_screen(one.yxx),	//4
		to_screen(one.yxy),	//5
		to_screen(one.yyx),	//6
		to_screen(one.yyy)	//7
	);
	//draw edges
	draw_line(p[0],p[1]);
	draw_line(p[0],p[2]);
	draw_line(p[0],p[4]);
	draw_line(p[1],p[3]);
	draw_line(p[1],p[5]);
	draw_line(p[2],p[3]);
	draw_line(p[2],p[6]);
	draw_line(p[3],p[7]);
	draw_line(p[4],p[5]);
	draw_line(p[4],p[6]);
	draw_line(p[5],p[7]);
	draw_line(p[6],p[7]);
}
