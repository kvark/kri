//#define USE_FILTER
#extension GL_ARB_texture_rectangle : require
uniform sampler2DRect texture;
const vec3 lumask = vec3(0.2125, 0.7154, 0.0721);

void main()	{
	#ifdef	USE_FILTER
	vec2 tc = gl_TexCoord[0].st, add = vec2(1.0,0.0);
	vec3 color = 0.25*(
		texture2DRect(texture, tc+add.xy)+
		texture2DRect(texture, tc-add.xy)+
		texture2DRect(texture, tc+add.yx)+
		texture2DRect(texture, tc-add.yx)
	).rgb;
	#else	//USE_FILTER
	vec3 color = texture2DRect(texture, gl_TexCoord[0].st).rgb;
	#endif	//USE_FILTER
	float bright = log(dot(color, lumask) + 0.25);
	color += 0.2*sin(-10.0*color/(color+2.0));
	gl_FragColor = vec4(color, bright);
}
