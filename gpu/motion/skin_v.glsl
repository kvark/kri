#version 150 core

in vec4 at_vertex;
out vec4 to_old, to_new;


uniform struct Spatial	{
	vec4 pos,rot;
}s_cam,s_model,s_offset;
uniform vec4 proj_cam;


vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
Spatial trans_combine(Spatial,Spatial);
vec4 get_projection(vec3,vec4);


Spatial skin_append_all();


void main()	{
	Spatial sof = trans_combine( s_offset, skin_append_all() );
	
	vec3 v1 = trans_for( at_vertex.xyz, s_model );
	vec3 vn = trans_inv( v1, s_cam );
	vec3 vo = trans_inv( vn, s_offset );

	to_old = get_projection(vo,proj_cam);
	to_new = get_projection(vn,proj_cam);
	gl_Position = to_new;
}
