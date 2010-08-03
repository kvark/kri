#version 130

uniform sampler2D unit_input;

noperspective in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	float d = texture(unit_input, tex_coord).r;
	rez_color = vec4( pow(d,50.0) );
	//rez_color = vec4( -log2(d) );
}
