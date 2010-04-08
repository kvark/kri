#version 130

in vec4 at_quat;
out vec4 color;

uniform struct Spatial	{
	vec4 pos,rot;
}s_model,s_cam;
uniform vec4 proj_cam;

vec4 fixed_proj(Spatial,vec4);

void main()	{
	gl_Position = fixed_proj(s_cam,proj_cam);
	color = at_quat;
}
