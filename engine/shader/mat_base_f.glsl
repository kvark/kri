#version 130
precision lowp float;

in vec4 coord_texture;

uniform struct Material	{
	vec4 emissive;
	vec4 diffuse;
	vec4 specular;
}mat;
uniform vec4 base_color;

vec4 mat_texture(vec4);

void main()	{
	vec4 emis = mat.emissive + base_color;
	gl_FragColor = emis * mat_texture(coord_texture);
}
