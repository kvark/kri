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
	[Getter(Ready)]
	private linked as bool = false
	private blocks	= List[of Object]()
	[Getter(Log)]
	private log	as string = ''

	public def constructor():
		id = GL.CreateProgram()
	protected def constructor(xid as int):
		id = xid
		linked = true
	def destructor():
		kri.Help.safeKill({ GL.DeleteProgram(id) })
	public def check(pp as ProgramParameter) as void:
		GL.GetProgramInfoLog(id,log)
		result as int
		GL.GetProgram(id, pp, result)
		return	if result
		print "Check ${pp} failed for program ${id}:\n${log}"
		raise log
	
	# add specific objects
	public def add(*shads as (Object)) as void:
		assert not linked
		blocks.Extend(shads)
		for sh in shads:
			GL.AttachShader(id, sh.id)	if sh
	# add object from library
	public def add(*names as (string)) as void:
		for s in names:
			add( Object.Load(s) )
	# link program
	public def link() as void:
		#assert not linked
		linked = true
		GL.LinkProgram(id)
		check( ProgramParameter.LinkStatus )
	# activate program
	public virtual def use() as void:
		assert linked
		if kri.Ant.Inst.debug:
			GL.ValidateProgram(id)
			check( ProgramParameter.ValidateStatus )
		GL.UseProgram(id)

	# assign vertex attribute slot
	public def attrib(index as int, name as string) as void:
		assert index < kri.Ant.Inst.caps.vertexAttribs
		GL.BindAttribLocation(id, index, name)
	# assign fragment output slot
	public def fragout(*names as (string)) as void:
		assert names.Length <= kri.Ant.Inst.caps.drawBuffers
		for i in range(names.Length):
			GL.BindFragDataLocation(id, i, names[i])
	# assign transform feedback
	public def feedback(sep as bool, *names as (string)) as void:
		GL.TransformFeedbackVaryings( id, names.Length, names,
		(TransformFeedbackMode.InterleavedAttribs,TransformFeedbackMode.SeparateAttribs)[sep] )

	# get uniform location by name
	public def getVar(name as string) as int:
		assert linked
		return GL.GetUniformLocation(id,name)
	# set uniform parameter value
	[ext.spec.ForkMethod(fun, GL.Uniform1, (int,single))]
	[ext.spec.ForkMethod(fun, GL.Uniform4, (Color4,Vector4,Quaternion))]
	public static def Param[of T(struct)](loc as int, ref val as T) as void:
		def fun(l as int, ref v as T) as void:
			assert 'Uniform type not supported'
		assert loc >= 0
		fun(loc,val)

	# clear everything
	public virtual def clear() as void:
		linked = false
		for sh in blocks:
			GL.DetachShader( id, sh.id )
		blocks.Clear()
