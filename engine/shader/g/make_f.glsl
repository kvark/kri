#version 130
precision lowp float;

vec4 get_bump();
vec4 get_diffuse();
vec4 get_specular();
float get_glossiness();

vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}

in vec4 v2cam, quat;
in vec4 coord_text, coord_bump;


void main()	{
	vec3 w_norm = qrot(normalize(quat), get_bump().xyz);
	w_norm.x *= v2cam.w;	//applying handness
	float glossy = 0.01 * get_glossiness();
	
	gl_FragData[0] = get_diffuse();
	gl_FragData[1] = get_specular();
	gl_FragData[2] = vec4(vec3(0.5) + 0.5*w_norm, glossy);
}
