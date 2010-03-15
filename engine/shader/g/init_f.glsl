#version 130
precision lowp float;

in vec2 tex_coord;

uniform sampler2DArray	unit_gbuf;

void main()	{
	gl_FragColor = vec4(0.0,0.0,0.0,1.0);
}