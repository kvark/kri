#version 140

uniform vec4 screen_size, lit_color;
uniform sampler2D unit_depth;

vec3 unproject(vec3,vec4);

const vec3 va = inversesqrt( vec3(1.5,0.0,3.0) );
const vec3 vb = inversesqrt( vec3(6.0,2.0,3.0) ) * vec3(-1.0,0.0,0.0);
const vec3 vc = inversesqrt( vec3(6.0,2.0,3.0) ) * vec3(-1.0,-1.0,0.0);

in vec3 lit_pos;	//cam space!
out vec4 ca,cb,cc;


void main()	{
	// extract world & light space
	float depth = texture(unit_depth, gl_FragCoord.xy).r;
	vec2 tc = gl_FragCoord.xy / screen_size.xy;
	vec3 p_camera = unproject( vec3(tc,depth), proj_cam );
	vec3 dir = lit_pos - p_camera;

	// compute components
	ca = dot(dir,va) * lit_color;
	cb = dot(dir,vb) * lit_color;
	cc = dot(dir,vc) * lit_color;
}