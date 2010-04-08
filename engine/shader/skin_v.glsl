#version 130

// Dual Quaternions support
#define DUALQUAT

in	vec4 at_vertex,at_quat;
in	uvec4 at_skin;
out	vec4 to_vertex,to_quat;

struct Spatial	{
	vec4 pos,rot;
};
const int NB = 80;
uniform Spatial bone[NB];

vec4 qinv(vec4);
vec4 qmul(vec4,vec4);
vec3 trans_for(vec3,Spatial);

#ifdef DUALQUAT
struct DualQuat	{
	vec4 re,im;
	float scale;
};
void addDq(inout DualQuat dq, in float w, in Spatial s)	{
	vec4 pos = vec4(0.5 * s.pos.xyz, 0.0);
	dq.re += w * s.rot;
	dq.im += w * qmul(pos,s.rot);
	dq.scale += w * s.pos.w;
}
Spatial normDq(inout DualQuat dq)	{
	float k = 1.0 / length(dq.re);
	vec4 tmp = qmul(dq.im, qinv(dq.re));
	tmp *= 2.0*k*k; tmp.w = dq.scale;
	return Spatial( tmp, k * dq.re );
}
#else
void append(inout Spatial s, in float w, in Spatial bone)	{
	s.pos.xyz += w * trans_for(at_vertex, bone);
	s.rot += w * qmul(bone.rot, at_quat);
}
#endif

void main()	{
	//to_vertex = at_vertex; to_quat = at_quat; return;
	uvec4 ids = at_skin >> uint(8);
	vec4 wes = vec4(at_skin & uvec4(255)) * (1.0/255.0);
	#ifdef DUALQUAT
	DualQuat rez = DualQuat( vec4(0.0), vec4(0.0), 0.0 );
	for(int i=0; i<4; ++i)
		addDq(rez, wes[i], bone[ids[i]]);
	Spatial sp = normDq(rez);
	vec3 v = trans_for(at_vertex.xyz, sp);
	to_vertex = vec4(v, at_vertex.w);
	to_quat = qmul(sp.rot, at_quat);
	#else
	Spatial sp = Spatial( vec4(0.0), vec4(0.0) );
	for(int i=0; i<4; ++i)
		append(sp, wes[i], bone[ids[i]]);
	to_vertex = vec4(sp.pos.xyz, at_vertex.w);
	to_quat = normalize(sp.rot);
	#endif
}