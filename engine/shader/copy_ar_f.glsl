#version 130

uniform sampler2DArray unit_input;
uniform float layer;

in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = 0.05*texture(unit_input, vec3(tex_coord,layer));
	//float dep = texture(unit_input, vec3(tex_coord,layer)).r;
	//rez_color = vec4( pow(dep,50.0) );
}
