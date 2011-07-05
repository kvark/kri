#version 130

uniform sampler2D unit_input;

uniform struct Spatial	{
	vec4 pos,rot;
}s_cam;

uniform vec4	proj_cam;


in	vec4	at_pos, at_rot;
in	vec4	at_low, at_hai;
out	bool	to_visible;

Spatial s_model = Spatial(at_pos,at_rot);

vec3 trans_for(vec3,Spatial);
vec3 trans_inv(vec3,Spatial);
vec4 get_projection(vec3,vec4);

vec3 to_ndc(vec3 v)	{
	vec3 w = trans_for(v,s_model);
	vec3 c = trans_inv(w,s_cam);
	vec4 p = get_projection(c,proj_cam);
	return (vec3(1.0) + p.xyz/p.w) * 0.5;
}

const vec2 one = vec2(0.0,1.0);
const vec3 mixer[] = vec3[8](
	one.xxx, one.xxy, one.xyx, one.xyy,
	one.yxx, one.yxy, one.yyx, one.yyy
);

void main()	{
	vec3 xmin = vec3(1.0), xmax = vec3(0.0);
	for(int i=0; i<8; ++i)	{
		vec3 pw = mix( at_low.xyz, -at_hai.xyz, mixer[i] );
		vec3 pc = to_ndc(pw);
		xmin = min(xmin,pc);
		xmax = max(xmax,pc);
	}
	ivec2 viewSize = textureSize(unit_input,0);
	float viewLen = length(viewSize);
	float len = distance( xmin.xy, xmax.xy );
	int lod = int(ceil(log2( len * viewSize )));
	vec4 sam;
	sam.x = textureLod( unit_input, xmin.xy, lod ).x;
	sam.y = textureLod( unit_input, vec2(xmin.x,xmax.y), lod ).x;
	sam.z = textureLod( unit_input, vec2(xmax.x,xmin.y), lod ).x;
	sam.w = textureLod( unit_input, xmax.xy, lod ).x;
	float maxDepth = max( max(sam.x,sam.w), max(sam.y,sam.z) );
	to_visible = xmin.z < maxDepth;
}
