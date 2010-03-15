#extension GL_ARB_texture_rectangle : require
uniform sampler2DRect texture;
uniform float kf;

void main()	{
	gl_FragColor = texture2DRect(texture, gl_TexCoord[0].st);
}
