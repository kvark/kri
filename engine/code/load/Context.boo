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
	
	# This method constructs a shader object code that links together:
	#	 meta_data - texture_unit - coordinate_source
	# It's the biggest GLSL code generation in KRI
	public def MakeTexCoords( geom as bool, dict as IDictionary[of string,Hermit] ) as Object*:
		rez = List[of Object]()
		def filterInputs(st as ShaderType):
			return array(h.Name	for h in dict.Values	if h.Shader.type == st)
		def genJoin(ar as string*, pattern as string):
			return join(pattern % (name,)	for name in ar)
		#: Vertex shader
		# most of map inputs are generated there
		vins = filterInputs( ShaderType.VertexShader )
		v_fun		= genJoin(vins,"\nvec3 mi_{0}();")
		vout = ('mr','mv')[geom]	# for the translation in geometry shader
		v_output	= genJoin(vins,"\nout vec3 ${vout}_{0};")
		v_body		= genJoin(vins,"\n\t${vout}_{0} = mi_{0}();")
		str = "#version 130\n${v_fun}\n${v_output}\nvoid make_tex_coords(){${v_body}\n}"
		rez.Add(Object( ShaderType.VertexShader, 'tc_vert_init', str ))
		#: Geometry shader
		# function 'emit_vert' accepts a strand coordinate (float tc) and calls EmitVertex after
		# vertex inputs are translated and geometry ones are generated
		gins = filterInputs( ShaderType.GeometryShader )
		if geom:
			g_input		= genJoin(vins,"\nin vec3 mv_{0};")
			g_output	= genJoin(vins+gins,"\nout vec3 mr_{0};")
			g_fun		= genJoin(gins,"\nvec4 mi_{0}(vec3);")
			g_body1		= genJoin(vins,"\n\tmr_{0} = mv_{0};")		# translation
			g_body2		= genJoin(gins,"\n\tmr_{0} = mi_{0}(tc);")	# generation
			g_full		= "\nvoid emit_vert(float tc) {${g_body1}${g_body2}\n\tEmitVertex();\n}"
			str = "#version 130\n" + g_input + g_output + g_fun + g_full
			rez.Add(Object( ShaderType.GeometryShader, 'tc_frag_init', str ))
		elif gins.Length: return null
		#: Fragment shader
		# accumulates vertex & geometry map inputs, has it's own generators
		# here is where the texture scale & offset are applied
		# parallax function (apply_tex_offset) is also here, affects only 'uv0'
		fins = filterInputs( ShaderType.FragmentShader )
		f_input	= genJoin(vins+gins,"\nin vec3 mr_{0};\nvec3 tr_{0} = mr_{0};")
		f_local = genJoin(fins,"\nvec3 mi_{0}();\nvec3 tr_{0} = mi_{0}();")
		# parallax
		f_par_body = ('','tr_uv0 += off;')['uv0' in vins]
		f_parallax = "\nvoid apply_tex_offset(vec3 off)	{\n\t${f_par_body}\n}"
		# uniforms
		f_uni	= join("\nuniform vec4 offset_{0},scale_{0};" % (d.Key,)	for d in dict)
		# getter function: tc_{target}()
		pattern = "\nvec4 tc_{0}() {2}\n\treturn offset_{0} + scale_{0} * vec4(tr_{1},1.0);\n{3}"
		f_fun 	= join(pattern % (d.Key,d.Value.Name,'{','}')	for d in dict)
		# together
		str = "#version 130\n" + f_input + f_local + f_parallax + f_uni + f_fun
		rez.Add(Object( ShaderType.FragmentShader, 'tc_frag_init', str ))
		# done
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
