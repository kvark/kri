#version 150 core

in float time;
out vec4 rez_color;

uniform float bright;

void main()	{
	//rez_color = vec4(1.0); return;
	vec2 r = 2.0*gl_PointCoord - vec2(1.0);
	float r2 = 1.0 - dot(r,r);
	float kf = 1.0 - exp(-bright*time);
	float red = min(1.0, 0.01*time);
	rez_color = vec4(kf*r2*red, kf*r2, 0.0, 1.0);
}
