#version 130

uniform samplerCube unit_light;

noperspective in vec2 tex_coord;
out vec4 rez_color;

void main()	{
	rez_color = texture(unit_light, vec3(tex_coord,1.0));
	//float dep = texture(unit_light, vec3(tex_coord,layer)).r;
	//rez_color = vec4( pow(dep,50.0) );
}
