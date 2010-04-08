#version 130

in vec4 to_vert;
in vec4 to_quat;
out vec4 r_vert;
out vec4 r_quat;

void main()	{
	r_vert = to_vert;
	r_quat = to_quat;
}
