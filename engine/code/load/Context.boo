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
	#	 meta_data - texture_unit - coordinate_source
	public def MakeTexCoords( geom as bool, dict as IDictionary[of string,Hermit] ) as Object*:
		# vertex shader
		vins = array(h.Name	for h in dict.Values	if h.Shader.type == ShaderType.VertexShader)
		def genJoin(pattern as string):
			return join(pattern % (name,)	for name in vins)
		v_fun		= genJoin("\nvec3 mi_{0}();")
		vout = ('mr','mv')[geom]
		v_output	= genJoin("\nout vec3 ${vout}_{0};")
		v_body		= genJoin("\n\t${vout}_{0} = mi_{0}();")
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
		f_par_body = join( "\n\ttr_${vu} += off;"	for vu in vins	if vu.StartsWith('uv') )
		f_parallax = "\nvoid apply_tex_offset(vec3 off)	{${f_par_body}\n}"
		f_uni	= join("\nuniform vec4 offset_{0},scale_{0};" % (d.Key,)	for d in dict)
		pattern = "\nvec4 tc_{0}() {2}\n\treturn offset_{0} + scale_{0} * vec4(tr_{1},1.0);\n{3}"
		f_fun 	= join(pattern % (d.Key,d.Value.Name,'{','}')	for d in dict)
		str = "#version 130\n" + f_input + f_local + f_parallax + f_uni + f_fun
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
