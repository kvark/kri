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
		'diffuse','specular','glossiness')
	
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

	public def MakeTexCoords2(cl as (string)*) as Object:
		key = join( (join(s,':') for s in cl), ';' )
		rez as Object = null
		if corDict.TryGetValue(key,rez):
			return rez
		def unilist(cl as string*) as string*:
			dd = Dictionary[of string,object]()
			for s in cl: dd[s] = null
			return dd.Keys
		layers = array[of string*](unilist(s[i] for s in cl) for i in range(3))
		def genStr(id as int, sp as string):
			return join( sp % (sv,) for sv in layers[id] )
		patBody = "tc_%1 = offset_%2 + scale_%2 * mr_%3;\n"
		sBody = join( patBody % sv	for sv in cl )
		dec_vars = genStr(0, "out vec4 tc_%1;\n" )
		dec_unis = genStr(1, "uniform vec4 offset_%1,scale_%1;\n" )
		dec_funs = genStr(2, "vec3 mi_%1();\n" )
		dec_mins = genStr(2, "vec4 mr_%1 = vec4( mi_%1(), 1.0);\n" )
		body = "void make_tex_coords()	{\n${dec_mins}\n${sBody}}"
		str = "#version 130\n" + dec_unis + dec_vars + dec_funs + body
		corDict[key] = rez = Object( ShaderType.VertexShader, 'tc_init', str )
		return rez


	public def MakeTexCoords3( dict as IDictionary[of string,Hermit] ) as Object*:
		# vertex shader
		vins = array(h.Name	for h in dict.Values	if h.Shader.type == ShaderType.VertexShader)
		def genJoin(pattern as string):
			return join(pattern % (name,)	for name in vins)
		v_fun		= genJoin("\nvec3 mi_{0}();")
		v_output	= genJoin("\nout vec3 mr_{0};")
		v_body		= genJoin("\n\tmr_{0} = mi_{0}();")
		str = "#version 130\n${v_fun}\n${v_output}\nvoid make_tex_coords(){${v_body}\n}"
		sh_vert = Object( ShaderType.VertexShader,		'tc_vert_init', str )
		# geometry shader
		# todo...
		# fragment shader
		f_input	= genJoin("\nin vec3 mr_{0};")
		def genStr(h as Hermit):
			if h.Shader.type == ShaderType.FragmentShader:
				pat = "\nvec3 mi_{0}();\nvec3 tr_{0} = mi_{0}();"
			else: pat = "\nvec3 tr_{0} = mr_{0};"
			return pat % (h.Name,)
		f_local = join(genStr(d.Value) for d in dict)
		f_uni	= join("\nuniform vec4 offset_{0},scale_{0};" % (d.Key,)	for d in dict)
		pattern = "\nvec4 tc_{0}() {2}\n\treturn offset_{0} + scale_{0} * vec4(tr_{1},1.0);\n{3}"
		f_fun 	= join(pattern % (d.Key,d.Value.Name,'{','}')	for d in dict)
		str = "#version 130\n" + f_input + f_local + f_uni + f_fun
		sh_frag = Object( ShaderType.FragmentShader,	'tc_frag_init', str )
		# done
		return (sh_vert,sh_frag)
		

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
			Color:Color4.White, Data:OpenTK.Vector4(0.1f,50f,0f,1f) ))
		mDef.link()
