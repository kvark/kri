#version 130

uniform samplerBuffer unit_part;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;


vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

in vec4 at_vertex;


void main()	{
	vec4 pos = texelFetch( unit_part, 1+3*gl_InstanceID );
	//pos = vec4(0.0, gl_InstanceID*0.3,0.0,1.0);
	if(dot(pos.xyz,pos.xyz) > 0.1)	{
		//vec3 v = pos.xyz + pos.w * at_vertex.xyz;
		vec3 v = pos.xyz + 0.3*at_vertex.xyz;
		vec3 vc = trans_inv(v,s_cam);
		gl_Position = get_projection(vc, proj_cam);
	}else	gl_Position = vec4(0.0,0.0,-2.0,1.0);
}
