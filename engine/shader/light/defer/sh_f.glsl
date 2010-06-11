#version 130

const float Pi = 3.1415926;
const float Sq1Pi = sqrt(1.0 / Pi);
const float Sq3Pi = sqrt(3.0) * Sq1Pi;

vec4 get_harmonics(vec3 dir)	{
	float r1 = inversesqrt( dot(dir,dir) );
	float s	= 0.5*Sq1Pi;
	vec3 p	= 0.5*Sq3Pi*r1 * dir;
	return vec4(p,s);
}
