#version 130
precision lowp float;

uniform vec4 screen_size;
uniform sampler2DRect unit_input;
in vec2 tex_coord;

void main()	{
	gl_FragColor = texture2DRect(unit_input, tex_coord * screen_size.xy);
}
