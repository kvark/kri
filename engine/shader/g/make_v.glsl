#version 130
precision lowp float;
//#define TBN


in vec3 at_vertex, at_tex;
in vec4 at_quat;
out vec4 coord_text, coord_bump;
out vec4 v2cam, quat;

#ifdef TBN
out vec3 my_norm, my_tang;
#endif


uniform struct Spatial	{
	vec4 pos,rot;
}s_model,s_cam;

uniform vec4 proj_cam;

//lib_quat
vec3 qrot(vec4,vec3);
vec4 qmul(vec4,vec4);
vec4 qinv(vec4);
vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
//lib_tool
vec4 get_projection(vec3,vec4);
//mat
vec4 tc_texture();
vec4 tc_bump();


void main()	{
	// vertex in world space
	vec3 v = trans_for(at_vertex, s_model);
	vec3 v_cam = s_cam.pos.xyz - v;

	// tangent->world transform
	quat = qmul( s_model.rot, at_quat );
	//storing handness in v2cam.w
	v2cam = vec4(qrot(qinv(quat),v_cam), at_tex.z);
	#ifdef TBN
	my_norm = qrot(quat, vec3(0.0,0.0,1.0));
	my_tang = qrot(quat, vec3(1.0,0.0,0.0));
	#endif TBN
	
	// vertex in camera space
	vec3 vc = trans_inv(v, s_cam);
	gl_Position = get_projection(vc, proj_cam);
	
	// gen coords
	coord_text = coord_bump = tc_texture();
}
