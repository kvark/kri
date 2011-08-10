#version 150 core

out vec4 rez_color;

void main()	{
	vec2 r2 = 2.0*gl_PointCoord - vec2(1.0);
	float rad = dot(r2,r2);
	rez_color = vec4(1.0-rad,0.0,0.0,1.0);
}
