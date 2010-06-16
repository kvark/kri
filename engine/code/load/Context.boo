namespace kri.load

import System.Collections.Generic
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL
import kri.shade
import kri.meta


#------		LOAD CONTEXT		------#

public static class Meta:
	private final tVert	= Template('/tmp/tc_v')
	private final tGeom	= Template('/tmp/tc_g')
	private final tFrag	= Template('/tmp/tc_f')
	public final LightSet	= ('bump','comp_diff','comp_spec',\
		'diffuse','specular','glossiness')
	
	# Provide a generator+translator shader for texture coordinates on each required stage
	# link together map_input, texture_unit & target_meta
	public def MakeTexCoords( geom as bool, dict as IDictionary[of string,Hermit] ) as Object*:
		def filterInputs(tmp as Template) as string*:
			return (h.Name	for h in dict.Values	if h.Shader.type == tmp.tip)
		def ar2dict(val as string*):
			d2 = Dictionary[of string,string]()
			for v in val: d2[v] = string.Empty
			return d2
		# create dict
		d = Dictionary[of string,IDictionary[of string,string]]()
		d['v'] = ar2dict( filterInputs(tVert) )
		d['g'] = ar2dict( filterInputs(tGeom) )
		d['f'] = ar2dict( filterInputs(tFrag) )
		d['o'] = ar2dict(( ('mr','mv')[geom], ))
		d['p'] = ar2dict( ((of string:,),('uv0',))['uv0' in filterInputs(tVert)] )
		d['t'] = d3 = Dictionary[of string,string]()
		for v in dict: d3.Add( v.Key, v.Value.Name )
		# instance list
		rez = List[of Object]()
		rez.Add( tVert.instance(d) )
		rez.Add( tGeom.instance(d) )	if geom
		rez.Add( tFrag.instance(d) )
		return rez


public class Shade:
	# light models
	public final lambert	= Object('/mod/lambert_f')
	public final cooktorr	= Object('/mod/cooktorr_f')
	public final phong		= Object('/mod/phong_f')
	# meta data
	public final emissive_u		= Object('/mod/emissive_u_f')
	public final emissive_t2	= Object('/mod/emissive_t2d_f')
	public final diffuse_u		= Object('/mod/diffuse_u_f')
	public final diffuse_t2		= Object('/mod/diffuse_t2d_f')
	public final specular_u		= Object('/mod/specular_u_f')
	public final glossiness_u	= Object('/mod/glossiness_u_f')
	public final bump_c			= Object('/mod/bump_c_f')
	# particles
	public final halo_u			= Object('/mod/halo_u_f')
	public final strand_u		= Object('/mod/strand_u_g')


public class Context:
	public final slib	= Shade()
	public final mDef	= kri.Material('default')
	
	public static def MakeTex(*data as (byte)) as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.bind()
		kri.Texture.Filter(false,false)
		GL.TexImage2D( tex.type, 0, PixelInternalFormat.Rgba8, 1,1,0,\
			PixelFormat.Rgba, PixelType.UnsignedByte, data )
		return tex
	
	public def constructor():
		mlis = mDef.metaList
		mlis.Add( Data[of single]('emissive',	slib.emissive_u,	0f ))
		mlis.Add( Data[of Color4]('diffuse',	slib.diffuse_u,		Color4.Gray ))
		mlis.Add( Data[of Color4]('specular',	slib.specular_u,	Color4.Gray ))
		mlis.Add( Data[of single]('glossiness',	slib.glossiness_u,	50f ))
		mlis.Add(Advanced	( Name:'bump', 		Shader:slib.bump_c ))
		mlis.Add(Advanced	( Name:'comp_diff',	Shader:slib.lambert ))
		mlis.Add(Advanced	( Name:'comp_spec',	Shader:slib.phong ))
		mlis.Add(Halo		( Name:'halo',		Shader:slib.halo_u,\
			Data:OpenTK.Vector4(0.1f,50f,0f,1f) ))
		mDef.link()
