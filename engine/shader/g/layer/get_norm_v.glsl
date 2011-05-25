#version 130

vec3 qrot(vec4,vec3);

in	vec3	at_normal;


vec3	make_normal(vec4 rot)	{
	return qrot( rot, at_normal );
}
