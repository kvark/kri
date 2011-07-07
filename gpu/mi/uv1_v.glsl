#version 130

in vec2 at_tex1;

vec3 mi_uv1()	{
	return vec3(at_tex1,0.0);
}
