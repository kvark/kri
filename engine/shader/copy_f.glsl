#version 130
precision lowp float;

in vec2 tex_coord;
uniform sampler2D unit_x;

void main()	{
	gl_FragColor = texture(unit_x, tex_coord);
	//gl_FragColor = vec4( pow(gl_FragColor.r,50.0) );
}
