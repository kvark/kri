#version 130
precision lowp float;

in vec3 at_vertex;
in vec4 at_quat;
out vec3 v2lit,v2cam;
out vec4 v_shadow;
out float lit_int;
out vec4 coord_text, coord_bump;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model,s_lit,s_cam;

uniform vec4 proj_cam, proj_lit;

//lib_quat
vec3 qrot(vec4,vec3);
vec4 qmul(vec4,vec4);
vec4 qinv(vec4);
vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);

//lib_tool
float get_attenuation(float);
vec4 get_projection(vec3,vec4);
float get_proj_depth(float,vec4);

//mat
vec4 tc_texture();
vec4 tc_bump();

void main()	{
	// vertex in world space
	vec3 v = trans_for(at_vertex, s_model);
	vec3 v_lit = s_lit.pos.xyz - v;
	vec3 v_cam = s_cam.pos.xyz - v;
	lit_int = get_attenuation( length(v_lit) );

	// vertex in camera space
	vec3 vc = trans_inv(v, s_cam);
	gl_Position = get_projection(vc, proj_cam);
	
	// gen coords
	coord_text = tc_texture();
	coord_bump = tc_bump();
	
	// world -> tangent space transform
	float handness = coord_text.z;
	vec4 quat = qinv(qmul( s_model.rot, at_quat ));
	v2lit = qrot(quat, v_lit);
	v2lit.x *= handness;
	v2cam = qrot(quat, v_cam);
	v2cam.x *= handness;
	
	// vertex in light space
	vec3 vl = trans_inv(v, s_lit);
	v_shadow = get_projection(vl,proj_lit);
}
