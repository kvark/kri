#version 130
precision lowp float;

void main()	{
	vec2 r2 = 2.0*gl_PointCoord - vec2(1.0);
	float rad = dot(r2,r2);
	gl_FragColor = vec4(1.0-rad,0.0,0.0,1.0);
}
