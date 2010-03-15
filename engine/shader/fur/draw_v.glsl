in	vec3 at_vertex;
in	vec4 at_quat;
in	vec3 at_fur_pos;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model;

uniform float shell_kf;

vec3 trans_for(vec3,Spatial);

void main()	{
	float kf = shell_kf * gl_InstanceId;
	vec3 root = trans_for(at_vertex, s_model);
	gl_Position = mix(root, at_fur_pos, kf);
}