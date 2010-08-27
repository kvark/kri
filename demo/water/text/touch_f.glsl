#version 130

out vec2 wave;
const float power = 30.0;

void main()	{
	vec2 pc = (vec2(0.5) - gl_PointCoord)*2.0;
	float rad = max(0.0, 1.0-dot(pc,pc) );
	wave = vec2( pow(rad,power), 0.0 );
}