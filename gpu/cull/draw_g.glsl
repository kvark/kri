#version 150 core

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


vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);


//	transform local coordinate into camera NDC

vec4 to_screen(vec3 mask)	{
	//vec3 v = mix( b[0].low.xyz, b[0].hai.xyz, mask );
	//Spatial s_model;
	//s_model.rot = to_rot[0];
	return vec4(0.0);	//ATI crashes with OOM
	//vec3 w = trans_for(v,s_model);
	//vec3 c = trans_inv(w,s_cam);
	//return get_projection(c,proj_cam);
}

void draw_line(vec4 a, vec4 b)	{
	gl_Position = a;
	EmitVertex();
	gl_Position = b;
	EmitVertex();
	EndPrimitive();
}


void main()	{
	const vec2 one = vec2(0.0,1.0);
	const vec3 mixer[] = vec3[8](
		one.xxx, one.xxy, one.xyx, one.xyy,
		one.yxx, one.yxy, one.yyx, one.yyy
	);
	vec4 p = to_screen(mixer[0]);
	//vec4	p[] = vec4[8](
	//	to_screen( mixer[i] );
	//}
	draw_line(p,p);
}
