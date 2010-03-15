#version 140
precision lowp float;

in vec4 to_vert;
in vec4 to_quat;

void main()	{
	gl_FragData[0] = to_vert;
	gl_FragData[1] = to_quat;
}
