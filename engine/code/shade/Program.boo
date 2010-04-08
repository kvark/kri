namespace kri.shade

import System
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


#-------------------------------#
#	STANDARD SHADER	PROGRAM		#
#-------------------------------#

public class Program:
	public final id as int
	[getter(Ready)]
	private linked as bool = false

	public def constructor():
		id = GL.CreateProgram()
	protected def constructor(xid as int):
		id = xid
		linked = true
	def destructor():
		kri.SafeKill({ GL.DeleteProgram(id) })
	public def check() as void:
		info as string
		GL.GetProgramInfoLog(id,info)
		#Debug.WriteLine("Program:\n" + info)
		result as int
		GL.GetProgram(id, ProgramParameter.LinkStatus, result)
		raise info	if not result
	
	# add specific objects
	public def add(*shads as (Object)) as void:
		assert not linked
		for sh in shads:
			GL.AttachShader(id, sh.id)	if sh
	# add object from library
	public def add(*names as (string)) as void:
		for s in names:
			add(( Object(s) if s.Substring(0,1) in ('/','.')
				else kri.Ant.Inst.shaders[s] ))
	# link program
	public def link() as void:
		#assert not linked
		linked = true
		GL.LinkProgram(id)
		check()

	# activate program
	public virtual def use() as void:
		assert linked
		GL.UseProgram(id)
	# assign vertex attribute slot
	public def attrib(index as int, name as string) as void:
		GL.BindAttribLocation(id, index, name)
	# assign fragment output slot
	public def fragout(*names as (string)) as void:
		for i in range(names.Length):
			GL.BindFragDataLocation(id, i, names[i])
	
	# get uniform location by name
	public def getVar(name as string) as int:
		assert linked
		return GL.GetUniformLocation(id,name)
	# set uniform parameter value
	[ext.spec.ForkMethod(fun, GL.Uniform1, int,single)]
	[ext.spec.ForkMethod(fun, GL.Uniform4, Color4,Vector4,Quaternion)]
	public static def Param[of T(struct)](loc as int, ref val as T) as void:
		def fun(l as int, ref v as T) as void:
			assert 'Uniform type not supported'
		assert loc >= 0
		fun(loc,val)
