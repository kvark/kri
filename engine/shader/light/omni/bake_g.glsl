#version 150 core

in gl_PerVertex	{
	vec4 gl_Position;
}gl_in[];

out gl_PerVertex	{
	vec4 gl_Position;
};


vec3 qrot2(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

uniform vec4 uni_dist;


void triMake(int lid, vec4 q)	{
	gl_Layer = lid;
	/*mat3 mx = mat3(
		vec3(q.w+q.x*q.x, 0.0, -q.x),
		vec3(0.0, q.w+q.y*q.y, -q.y),
		vec3(q.x, q.y, q.w*q.w)
	);*/	
	for(int i=0; i<3; ++i)	{
		//vec3 v = mx * gl_in[i].gl_Position.xyz;
		vec3 v = qrot2(q, gl_in[i].gl_Position.xyz);
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