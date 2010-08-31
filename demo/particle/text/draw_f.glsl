#version 130

uniform vec4 halo_data;
uniform sampler1D unit_color;

in float part_age;
out vec4 rez_color;

const float dark = 2.0, trans = 0.1, scale = 1.0/5.0;

void main()	{
	vec2 rad = 2.0*gl_PointCoord - vec2(1.0);
	//float r3 = 1.0-dot(rad,rad);	//old one
	float h = dark*(0.1 + 0.01 * halo_data.y);
	//hyper-circle equasion x^n + y^n = 1
	float r2 = pow( dot(rad,rad), 0.5/h );
	float r3 = trans * pow( 1.0-r2, h );
	rez_color = r3 * texture(unit_color, scale*part_age);
	if( rez_color.w < 0.01 ) discard;
}
