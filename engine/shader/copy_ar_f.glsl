#version 130
precision lowp float;

in vec2 tex_coord;
uniform sampler2DArray unit_input;
uniform float layer;

void main()	{
	gl_FragColor = 0.05*texture(unit_input, vec3(tex_coord,layer));
	//float dep = texture(unit_input, vec3(tex_coord,layer)).r;
	//gl_FragColor = vec4( pow(dep,50.0) );
}
