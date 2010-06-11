#version 140

uniform vec4 screen_size, lit_color, proj_cam;
uniform sampler2D unit_depth;

vec3 unproject(vec3,vec4);
vec4 get_harmonics(vec3);

in vec3 lit_pos;	//cam space!
out vec4 ca,cb,cc;


void main()	{
	// extract world & light space
	float depth = texture(unit_depth, gl_FragCoord.xy).r;
	vec2 tc = gl_FragCoord.xy / screen_size.xy;
	vec3 p_camera = unproject( vec3(tc,depth), proj_cam );
	
	// compute components
	vec4 kf = get_harmonics(lit_pos - p_camera);

	// translate to output
	ca = lit_color.r * kf + vec4(0.5);
	cb = lit_color.g * kf + vec4(0.5);
	cc = lit_color.b * kf + vec4(0.5);
}