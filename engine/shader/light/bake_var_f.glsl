#version 130
precision lowp float;

in float depth;

void main()	{
	gl_FragColor = vec4(depth, depth*depth, 0.0,1.0);
}
