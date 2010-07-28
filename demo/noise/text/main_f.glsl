#version 130

uniform vec4 cur_time,mouse_coord;
const float freq = 5.0, amp = 1.0, speed = 5.0;

float snoise(vec2);
float snoise(vec3);
float turbulence(vec2,vec3,int);
float turbulence(vec3,vec4,int);

out vec4 color;
noperspective in vec2 tex_coord;


void main()	{
	//float val = snoise(freq*tex_coord);
	float val = turbulence( vec3(freq*tex_coord,cur_time.x), vec4(1.5,1.5,1.0,0.5), 5 );
	color = vec4( 0.5*val+0.5 ); return;
	vec2 dir = 2.0*mouse_coord.xy - vec2(1.0);
	vec2 tc = freq*(tex_coord + speed * cur_time.yy*dir);
	tc = freq * tex_coord;
	//float random = snoise(tc) * amp;
	vec2 r2 = vec2( snoise(vec3(tc,0.0)), snoise(vec3(tc,1.0)) ) * amp;
	//r2 = vec2( snoise(tc) ) * amp;
	color = vec4( (r2.xy+vec2(1.0)) * 0.5, 0.0, 1.0 );
}