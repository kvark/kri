#version 130
precision lowp float;

in vec2 tex_coord;
uniform samplerCube unit_light;

void main()	{
	gl_FragColor = texture(unit_light, vec3(tex_coord,1.0));
	//float dep = texture(unit_light, vec3(tex_coord,layer)).r;
	//gl_FragColor = vec4( pow(dep,50.0) );
}
