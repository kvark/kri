#version 130
precision lowp float;

in vec3 at_vertex;
out vec2 tex_coord;

uniform vec4 area;

void main()	{
	vec2 v = area.xy + at_vertex.xy * area.zw;
	gl_Position = vec4(v, 0.0,1.0);
	tex_coord = v*0.5 + vec2(0.5);
}
