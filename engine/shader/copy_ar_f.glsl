#version 130
precision lowp float;

in vec2 tex_coord;
uniform sampler2DArray unit_x;
uniform float layer;

void main()	{
	gl_FragColor = 0.05*texture(unit_x, vec3(tex_coord,layer));
	float dep = texture(unit_x, vec3(tex_coord,layer)).r;
	//gl_FragColor = vec4( pow(dep,50.0) );
}
