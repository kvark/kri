namespace kri.load

import System.Collections.Generic
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL
import kri.shade
import kri.meta


#------		LOAD CONTEXT		------#

public static class Meta:
	private corDict = Dictionary[of string,Object]()
	
	public def MakeTexCoords(cl as List[of string]) as Object:
		key = string.Join(';',array(cl))
		rez as Object = null
		if corDict.TryGetValue(key,rez):
			return rez
		def unilist(cl as string*) as string*:
			dd = Dictionary[of string,object]()
			for s in cl: dd[s] = null
			return dd.Keys
		layers = array[of string*](unilist(s.Split(char(','))[i] for s in cl) for i in range(3))
		def genStr(id as int, sep as string, fun as callable(string) as string):
			return string.Join(sep,	array(fun(x) for x in layers[id]))
		def funBody(s as string) as string:
			x = s.Split(char(','))
			return " tc_${x[0]} = offset_${x[1]} + scale_${x[1]} * mi_${x[2]}();"
		dec_vars = genStr(0,',',	{s| return "tc_${s}"})
		dec_unis = genStr(1,',',	{s| return "offset_${s},scale_${s}"})
		dec_funs = genStr(2,"\n",	{s| return "vec4 mi_${s}();"})
		body = string.Join("\n", array(funBody(s) for s in cl))
		dec_all = "uniform vec4 ${dec_unis};\n out vec4 ${dec_vars};\n ${dec_funs}\n"
		str = kri.Ant.Inst.shaders.header + dec_all + "void make_tex_coords()	{\n ${body} \n}"
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
		mlis.Add(Data_Color4( Name:'emissive',	shader:slib.emissive_u,	Value:Color4.DarkGray ))
		mlis.Add(Data_Color4( Name:'diffuse',	shader:slib.diffuse_u,	Value:Color4.Gray ))
		mlis.Add(Data_Color4( Name:'specular',	shader:slib.specular_u,	Value:Color4.White ))
		mlis.Add(Data_single( Name:'glossiness',	shader:slib.glossiness_u,	Value:0.5f ))
		mlis.Add(Advanced	( Name:'bump', shader:slib.bump_c ))
