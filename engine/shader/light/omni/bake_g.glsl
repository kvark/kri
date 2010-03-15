#version 140
precision lowp float;

in vec3 pos[3];

uniform vec4 uni_dist;

void trimake(vec4 q)	{
	mat3 mx = mat3(
		vec3(q.w+q.x*q.x, 0.0, -q.x),
		vec3(0.0, q.w+q.y*q.y, -q.y),
		vec3(q.x, q.y, q.w*q.w)
	);	
	for(int i=0; i<3; ++i)	{
		vec3 v = mx * pos[i];
		float k = (2.0*v.z + uni_dist.y) * uni_dist.x;
		gl_Position = vec4(v.xy, -v.z*vec2(k,1.0));
		EmitVertex();
	}
	EndPrimitive();
}

void main()	{
	gl_Layer = 0;	trimake( vec4(0,0,0,1)	);
	gl_Layer = 1;	trimake( vec4(0,0,0,-1)	);
	gl_Layer = 2;	trimake( vec4(1,0,0,0)	);
	gl_Layer = 3;	trimake( vec4(-1,0,0,0)	);
	gl_Layer = 4;	trimake( vec4(0,1,0,0)	);
	gl_Layer = 5;	trimake( vec4(0,-1,0,0)	);
}