#version 130

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
void make_tex_coords();

in vec4 at_vertex, at_quat;
out vec4 quat;
out float handness;


void main()	{
	make_tex_coords();

	// vertex in world space
	vec3 v = trans_for(at_vertex.xyz, s_model);

	// tangent->world transform
	quat =  qmul( s_model.rot, at_quat );
	handness = at_vertex.w;
	
	// vertex in camera space
	vec3 vc = trans_inv(v, s_cam);
	gl_Position = get_projection(vc, proj_cam);
}
