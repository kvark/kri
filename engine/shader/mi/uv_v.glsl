#version 130
precision lowp float;

uniform int index;
//in vec2 at_tex[4];
in vec2 at_tex0;

vec3 mi_uv()	{
	//return vec3(at_tex[index],0.0);
	vec2 ar[] = vec2[](at_tex0);
	return vec3(ar[index],0.0);
}
