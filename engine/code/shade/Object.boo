namespace kri.shade

import OpenTK.Graphics.OpenGL


#---------------------------#
#	STANDARD SHADER	OBJECT	#
#---------------------------#

public class Object:
	internal final id	as int
	private final tag	as string
	public final type	as ShaderType

	private def compose(text as string) as int:
		sid = GL.CreateShader(type)
		GL.ShaderSource(sid,text)
		GL.CompileShader(sid)
		Check(sid)
		return sid
	private def compose() as int:
		return compose( Code.Read(tag) )
		

	# create by name & type
	public def constructor(name as string, tip as ShaderType):
		tag,type = name,tip
		id = compose()

	# create by name, infer the type from it
	public def constructor(name as string):
		type = cast(ShaderType,0)
		if		name.EndsWith('_v'):	type = ShaderType.VertexShader
		elif	name.EndsWith('_f'):	type = ShaderType.FragmentShader
		elif	name.EndsWith('_g'):	type = ShaderType.GeometryShader
		tag = name
		id = compose()

	# create from source
	public def constructor(tip as ShaderType, label as string, text as string):
		assert text.Length
		tag,type = label,tip
		id = compose(text)

	# delete
	def destructor():
		kri.safeKill({ GL.DeleteShader(id) })

	# check compilation result
	private def Check(sid as int) as void:
		info as string
		GL.GetShaderInfoLog(sid,info)
		#Debug.WriteLine("Shader: "+tag+"\n"+info);
		result as int
		GL.GetShader(sid, ShaderParameter.CompileStatus, result)
		raise info	if not result
	
	# check current shader
	public def check() as void:
		Check(id)

	# disable shading
	public static def off() as void:
		GL.UseProgram(0)
