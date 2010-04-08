#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;

vec4 fixed_proj(Spatial,vec4);

vec3 mi_window()	{
	vec4 v = fixed_proj(s_cam,proj_cam);
	return (v.xyz / v.w)*0.5 + vec3(0.5);
}
