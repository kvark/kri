#version 130

noperspective in vec2 tex_coord;
out vec4 color;

uniform sampler2D unit_input;
uniform sampler2D unit_velocity;
uniform float radius;

const float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );
const float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );


void main()	{
	vec2 vl = texture(unit_velocity,tex_coord).xy;
	color = vec4(0.0);
	for(int i=0; i<3; ++i)	{
		vec2 tc = tex_coord - (radius*offset[i]) * vl;
		color += weight[i] * texture(unit_input,tc);
	}
}