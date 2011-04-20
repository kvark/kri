namespace kri.shade

import OpenTK.Graphics.OpenGL


#---------------------------#
#	STANDARD SHADER	OBJECT	#
#---------------------------#

public class Object:
	public final handle		as int
	[Getter(Description)]
	private final tag		as string
	public final type		as ShaderType

	public static def Type(name as string) as ShaderType:
		rez = cast(ShaderType,0)
		if		name.EndsWith('_v'):	rez = ShaderType.VertexShader
		elif	name.EndsWith('_f'):	rez = ShaderType.FragmentShader
		elif	name.EndsWith('_g'):	rez = ShaderType.GeometryShader
		return rez
	
	public static def Load(path as string) as Object:
		return kri.Ant.Inst.dataMan.load[of Object](path)
	
	# create from source
	public def constructor(tip as ShaderType, label as string, text as string):
		assert text.Length
		tag,type = label,tip
		handle = compose(text)
		check()
	
	# delete
	def destructor():
		kri.Help.safeKill({ GL.DeleteShader(handle) })

	private def compose(text as string) as int:
		sid = GL.CreateShader(type)
		GL.ShaderSource(sid,text)
		GL.CompileShader(sid)
		return sid

	# check compilation result
	private def check() as void:
		info as string
		GL.GetShaderInfoLog(handle,info)
		#Debug.WriteLine("Shader: "+tag+"\n"+info);
		result as int
		GL.GetShader(handle, ShaderParameter.CompileStatus, result)
		if not result:
			kri.lib.Journal.Log("Shader: Failed to compile object (${tag}), message: ${info}")
