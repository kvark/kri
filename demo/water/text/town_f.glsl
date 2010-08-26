#version 130

const float freq = 5.0, amp = 1.0;

float snoise(vec2);
float turbulence(vec2,vec3,int);

out vec4 color;
noperspective in vec2 tex_coord;


void main()	{
	float val = turbulence( freq*tex_coord, vec3(1.5,1.5,0.5), 3 );
	color = vec4( 0.5*val+0.5 );
}