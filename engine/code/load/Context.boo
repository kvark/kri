namespace kri.load

import System.Collections.Generic
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL
import kri.shade
import kri.meta


#------		LOAD CONTEXT		------#

public static class Meta:
	private corDict = Dictionary[of string,Object]()
	public final LightSet	= ('bump','comp_diff','comp_spec',\
		'mat_diffuse','mat_specular','mat_glossiness')
	
	# this method constructs a shader object code that links together:
	#	 meta_data - texture - coordinate_source
	public def MakeTexCoords(cl as (string)*) as Object:
		key = join( (join(s,':') for s in cl), ';' )
		rez as Object = null
		if corDict.TryGetValue(key,rez):
			return rez
		def unilist(cl as string*) as string*:
			dd = Dictionary[of string,object]()
			for s in cl: dd[s] = null
			return dd.Keys
		layers = array[of string*](unilist(s[i] for s in cl) for i in range(3))
		def genStr(id as int, fun as callable(string) as string):
			return join(map( layers[id], fun ))
		def funBody(s as (string)) as string:
			return "tc_${s[0]} = offset_${s[1]} + scale_${s[1]} * mr_${s[2]};\n"
		dec_vars = genStr(0, {s| return "out vec4 tc_${s};\n" })
		dec_unis = genStr(1, {s| return "uniform vec4 offset_${s},scale_${s};\n" })
		dec_funs = genStr(2, {s| return "vec3 mi_${s}();\n" })
		dec_mins = genStr(2, {s| return "vec4 mr_${s} = vec4( mi_${s}(), 1.0);\n" })
		body = "void make_tex_coords()	{\n${dec_mins}\n${join(map(cl,funBody))}}"
		str = "#version 130\n" + dec_unis + dec_vars + dec_funs + body
		corDict[key] = rez = Object( ShaderType.VertexShader, 'tc_init', str )
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
	# halo
	public final halo_u			= Object('/mod/halo_u_f')
	public final halo_t2		= Object('/mod/halo_t2d_f')


public class Context:
	public final slib	= Shade()
	public final mDef	= kri.Material('default')
	
	public static def MakeTex(*data as (byte)) as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2D )
		tex.bind()
		kri.Texture.Filter(false,false)
		kri.Texture.Init(1,1, PixelInternalFormat.Rgba8, data)
		return tex
	
	public def constructor():
		mlis = mDef.metaList
		mEmis = Data[of single]('emissive')
		mEmis.Shader = slib.emissive_u
		mEmis.Value = 0f
		mDiff = Data[of Color4]('diffuse')
		mDiff.Shader = slib.diffuse_u
		mDiff.Value = Color4.Gray
		mSpec = Data[of Color4]('specular')
		mSpec.Shader = slib.specular_u
		mSpec.Value = Color4.Gray
		mGlos = Data[of single]('glossiness')
		mGlos.Shader = slib.glossiness_u
		mGlos.Value = 50f
		mlis.AddRange((of IAdvanced: mEmis,mDiff,mSpec,mGlos))
		mlis.Add(Advanced	( Name:'bump', 		Shader:slib.bump_c ))
		mlis.Add(Advanced	( Name:'comp_diff',	Shader:slib.lambert ))
		mlis.Add(Advanced	( Name:'comp_spec',	Shader:slib.phong ))
		mlis.Add(Halo		( Name:'halo',		Shader:slib.halo_u,\
			Color:Color4.White, Data:OpenTK.Vector4(0.1f,50f,0f,1f) ))
		mDef.link()
