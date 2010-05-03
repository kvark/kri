#version 130

in vec4 at_vertex;
noperspective out vec2 tex_coord;

void main()	{
	gl_Position = at_vertex;
	tex_coord = at_vertex.xy*0.5 + vec2(0.5);
}
