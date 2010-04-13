#version 130

uniform vec4 halo_color, halo_data;

out vec4 rez_color;

const float dark = 2.0;

void main()	{
	vec2 rad = 2.0*gl_PointCoord - vec2(1.0);
	//float r3 = 1.0-dot(rad,rad);	//old one
	float h = dark*(0.1 + 0.01 * halo_data.y);
	//hyper-circle equasion x^n + y^n = 1
	float r2 = pow( dot(rad,rad), 0.5/h );
	float r3 = pow( 1.0-r2, h );
	if( r3*halo_color.w < 0.01 ) discard;
	rez_color = vec4(halo_data.zzz,0.0) + r3*halo_color;
}
