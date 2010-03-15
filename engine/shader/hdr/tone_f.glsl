#extension GL_ARB_texture_rectangle : require
uniform sampler2DRect texture;
uniform float exposure;

void main()	{
	vec3 color = texture2DRect(texture, gl_TexCoord[0].st).rgb;
	gl_FragColor = vec4(1.0) - vec4(exp(-exposure*color),0.0);
}
