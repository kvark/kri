#version 130
precision lowp float;

in vec2 tex_coord;

//---	UNIFORMS	---//

uniform sampler2DRect	unit_depth;
uniform sampler2DArray	unit_gbuf;
uniform sampler2D	unit_light;

uniform struct Spatial	{
	vec4 pos,rot;
}s_lit,s_cam;

uniform vec4 screen_size, proj_cam, proj_lit;
uniform vec4 lit_color, lit_data, lit_attenu;


//---	LIGHT MODEL		---//

float comp_diffuse(vec3 no, vec3 lit)	{
	//lambert model
	return max( dot(no,lit), 0.0);
}
float comp_specular(vec3 no, vec3 lit, vec3 cam, float power)	{
	//cook-torrance model
	float nh = dot(no, normalize(lit+cam) );
	if(nh <= 0.0) return 0.0;
	float nv = max(dot(no,cam), 0.0);
	float sf = pow(nh, power);
	return sf/(0.1+nv);
}
float get_attenuation(float d)	{
	vec3 a = vec3(1.0) + lit_attenu.wyz * vec3(-d,d,d*d);
	//x: spherical, y :linear, z: quadratic
	return a.x * lit_attenu.x / (a.y*a.z);
}


//---	TRANSFORMATIONS		---//

vec3 qrot(vec4 q, vec3 v)	{
	return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
vec3 trans_for(vec3 v, Spatial s)	{
	return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
}
vec3 trans_inv(vec3 v, Spatial s)	{
	return qrot( vec4(-s.rot.xyz, s.rot.w), (v-s.pos.xyz)/s.pos.w );
}

vec4 get_projection(vec3 v, vec4 pr)	{
	return vec4( v.xy * pr.xy, v.z*pr.z + pr.w, -v.z);
}
vec3 unproject(vec3 v, vec4 pr)	{
	vec3 ndc = 2.0*v - vec3(1.0);
	float z = -pr.w / (ndc.z + pr.z);
	return z * vec3(-ndc.xy / pr.xy, 1.0);
}


//---	MAIN	---//

void main()	{
	float depth = texture(unit_depth, screen_size.xy*tex_coord).r;
	vec3 p_camera = unproject( vec3(tex_coord,depth), proj_cam );
	vec3 p_world	= trans_for(p_camera, s_cam);
	vec3 p_light	= trans_inv(p_world, s_lit);
	
	vec4 g_diffuse	= texture(unit_gbuf, vec3(tex_coord,0.0));
	vec4 g_specular	= texture(unit_gbuf, vec3(tex_coord,1.0));
	vec4 g_normal	= texture(unit_gbuf, vec3(tex_coord,2.0));
	vec3 normal = 2.0*g_normal.xyz - vec3(1.0);	//world space
	// no normalization needed for 1-to-1 G-buffer
	
	vec3 v_lit = s_lit.pos.xyz - p_world;
	vec3 v2lit = normalize( v_lit );
	vec3 v2cam = normalize( s_cam.pos.xyz - p_world );
	float diff = comp_diffuse(	normal, v2lit );
	float spec = comp_specular(	normal, v2lit, v2cam, 100.0*g_normal.w );

	float intensity = get_attenuation( length(v_lit) );
	gl_FragColor = intensity*lit_color * (diff * g_diffuse + spec * g_specular);
	//gl_FragColor = g_diffuse + 0.1*lit_color;
}