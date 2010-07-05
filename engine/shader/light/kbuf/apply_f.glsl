#version 150 core

uniform sampler2DMS unit_light;
const vec4 lit_color = vec4(1.0);

// material data
vec4 get_bump();
vec4 get_emissive();
vec4 get_diffuse();
vec4 get_specular();
float get_glossiness();


in vec4 tan2cam;	// tangent->camera rotation
in vec4 v_cam;		// vertex in camera space
out vec4 rez_color;

vec3 qrot2(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}


void main()	{
	// camera space normal
	vec3 bump = get_bump().xyz * vec3(v_cam.w,1.0,1.0);
	vec3 normal = qrot2( tan2cam, bump );
	vec3 reflected = reflect( normalize(v_cam.xyz), normal );

	ivec2 itc = ivec2( gl_FragCoord.xy );
	vec4 kd = vec4(0.0), ks = vec4(0.0), kw = vec4(0.0);

	for(int i=0; i<2; ++i)	{
		vec4 data = texelFetch(unit_light, itc, i);
		//rez_color = vec4(length(data)); return;
		vec3 dir = data.xyz;
		kd[i] = max(0.0, dot(dir,normal));
		ks[i] = max(0.0, dot(dir,reflected));
		kw[i] = data.w;
	}
	
	ks = pow( ks, vec4(get_glossiness()) );
	vec4 diffuse = get_diffuse(), specular = get_specular();

	rez_color = get_emissive() + lit_color*
		(kw[0]*(diffuse*kd[0] + specular*ks[0]));
}
