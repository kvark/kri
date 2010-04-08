#version 130

uniform sampler2D unit_input;

in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = texture(unit_input, tex_coord);
	//rez_color = vec4( pow(rez_color.r,50.0) );
}
