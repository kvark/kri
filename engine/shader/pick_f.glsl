#version 130
precision lowp float;

uniform float index;
//uniform int index;
//out uvec4 out_index;

void main()	{
	//out_index = uvec4(index);
	gl_FragColor.x = index;
}
