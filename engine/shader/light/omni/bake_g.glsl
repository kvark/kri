#version 140

layout(triangles) in;
layout(triangle_strip, max_vertices = 18) out;


in vec3 pos[];

vec3 qrot2(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

uniform vec4 uni_dist;


void triMake(int lid, vec4 q)	{
	gl_Layer = lid;
	for(int i=0; i<3; ++i)	{
		vec3 v = qrot2(q, pos[i]);
		float k = (2.0*v.z + uni_dist.y) * uni_dist.x;
		gl_Position = vec4( v.xy, -v.z*vec2(k,1.0) );
		EmitVertex();
	}
	EndPrimitive();
}

void main()	{
	vec3 v = vec3(1.0,-1.0,0.0);
	triMake(0, v.zzzx );
	triMake(1, v.zzzy );
	triMake(2, v.xzzz );
	triMake(3, v.yzzz );
	triMake(4, v.zxzz );
	triMake(5, v.zyzz );
}