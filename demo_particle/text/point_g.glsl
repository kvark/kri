#version 140
precision lowp float;

void main()	{
	gl_PointSize = gl_PointSizeIn[0];
	vec4 p = gl_PositionIn[0];
	for(int i=0; i<4; ++i)	{
		gl_Position = p;
		EmitVertex();
		p.x += 0.05*p.w;
	}
}