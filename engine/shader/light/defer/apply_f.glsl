#version 130

uniform sampler2DArray unit_light;

// material data
vec4 get_bump();
vec4 get_emissive();
vec4 get_diffuse();
vec4 get_specular();

// deferred funcs
vec3 qrot2(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
vec4 get_harmonics(vec3);


in vec2	tc;		// screen-space tex-coord
in vec4 tan2cam;	// tangent->camera rotation
in vec4 v_cam;		// vertex in camera space
out vec4 rez_color;


void main()	{
	vec4 ca = texture( unit_light, vec3(tc,0.0) );
	vec4 cb = texture( unit_light, vec3(tc,1.0) );
	vec4 cc = texture( unit_light, vec3(tc,2.0) );
	mat4 cm = mat4( ca,cb,cc, vec4(0.0,0.0,0.0,1.0) );
	
	// camera space normal
	vec3 bump = get_bump().xyz * vec3(v_cam.w,1.0,1.0);
	vec3 normal = qrot2(tan2cam,bump);
	vec3 reflected = reflect( normalize(v_cam.xyz), normal );
	vec4 kn = get_harmonics(normal);
	vec4 kr = get_harmonics(reflected);
	
	rez_color =
		+ (kn*cm) * get_diffuse()
	//	+ (kr*cm) * get_specular()
		+ get_emissive();
}
