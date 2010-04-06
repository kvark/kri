namespace kri.shade

import System.IO
import OpenTK.Graphics.OpenGL


#---------------------------#
#	STANDARD SHADER	OBJECT	#
#---------------------------#

public class Object:
	internal final id as int
	final tag as string

	public static def readText(name as string) as string:
		if name.StartsWith('/'):
			name = '../engine/shader' + name
		name += '.glsl'
		kri.res.check(name)
		return File.OpenText(name).ReadToEnd()

	private def compose() as void:
		text = readText(tag)
		GL.ShaderSource(id,text)
		GL.CompileShader(id)
		check()

	# create by name & type
	public def constructor(name as string, tip as ShaderType):
		tag = name
		id = GL.CreateShader(tip)
		compose()

	# create by name, infer the type from it
	public def constructor(name as string):
		tip as ShaderType
		if		name.EndsWith('_v'):
			tip = ShaderType.VertexShader
		elif	name.EndsWith('_f'):
			tip = ShaderType.FragmentShader
		elif	name.EndsWith('_g'):
			tip = ShaderType.GeometryShader
		tag = name
		id = GL.CreateShader(tip)
		compose()

	# create from source
	public def constructor(tip as ShaderType, label as string, *text as (string)):
		tag = label
		id = GL.CreateShader(tip)
		GL.ShaderSource(id, text.Length, text, null)
		GL.CompileShader(id)
		check()

	# delete
	def destructor():
		kri.SafeKill({ GL.DeleteShader(id) })

	# check compilation result
	public def check() as void:
		info as string
		GL.GetShaderInfoLog(id,info)
		#Debug.WriteLine("Shader: "+tag+"\n"+info);
		result as int
		GL.GetShader(id, ShaderParameter.CompileStatus, result)
		raise info	if not result

	# disable shading
	public static def off() as void:
		GL.UseProgram(0)
