#version 130
precision lowp float;

in vec3 at_vertex;
out vec2 tex_coord;

uniform vec4 area;

void main()	{
	vec3 v = area.xyz + at_vertex * area.w;
	gl_Position = vec4(v,1.0);
	tex_coord = v.xy*0.5 + vec2(0.5);
}
