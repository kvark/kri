#version 130
precision lowp float;
//#define TBN

uniform struct Material	{
	vec4 emissive;
	vec4 diffuse;
	vec4 specular;
}mat;
uniform vec4 mat_scalars;

vec4 mat_texture(vec4);
vec4 mat_bump(vec4);
vec4 mat_shift(vec4,vec3);

#ifdef	TBN
in vec3 my_norm, my_tang;
#endif
in vec4 v2cam, quat;
in vec4 coord_text, coord_bump;

vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

void main()	{
	vec4 tc = mat_shift(coord_text, normalize(v2cam.xyz));
	vec4 text = mat_texture(tc);
	vec4 bump = mat_bump(tc);
	vec3 w_norm = qrot(normalize(quat), bump.xyz);
	w_norm.x *= v2cam.w;	//applying handness
	
	#ifdef	TBN
	vec3 n = normalize(my_norm);
	vec3 t = normalize(my_tang);
	vec3 b = cross(n,t);
	t = cross(b,n);
	mat3 tbn = mat3(t,b,n);
	w_norm = tbn * bump.xyz;
	#endif	TBN
	
	gl_FragData[0] = mat_scalars.x * mat.diffuse * text;
	gl_FragData[1] = mat_scalars.y * mat.specular;
	gl_FragData[2] = vec4(vec3(0.5) + 0.5*w_norm, 0.01*mat_scalars.z);
}
