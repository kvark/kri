#version 150 core

in vec3 at_color0;
out vec4 color;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;
uniform vec4 proj_cam;

vec4 fixed_proj(Spatial,vec4);


void main()	{
	gl_Position = fixed_proj(s_cam,proj_cam);
	color = vec4( at_color0/255.0, 0.0 );
}
