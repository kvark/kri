namespace kri.shade

import System
import OpenTK
import OpenTK.Graphics
import OpenTK.Graphics.OpenGL


#-------------------------------#
#	STANDARD SHADER	PROGRAM		#
#-------------------------------#

public class Program:
	public final	handle	as int
	[Getter(Ready)]
	private linked	as bool = false
	private static	Current	as Program	= null
	[Getter(Log)]
	private log		as string = ''
	private final	blocks	= List[of Object]()	# for debug

	public def constructor():
		handle = GL.CreateProgram()
	protected def constructor(xid as int):
		handle = xid
		linked = true
	def destructor():
		if Current==self:
			Current = null
		kri.Help.safeKill({ GL.DeleteProgram(handle) })
	
	public static Zero	= Program(0)
	
	public def check(pp as ProgramParameter) as void:
		GL.GetProgramInfoLog(handle,log)
		result as int
		GL.GetProgram(handle, pp, result)
		return	if result
		print "Check ${pp} failed for program ${handle}:\n${log}"
		raise log
	
	public def validate() as void:
		GL.ValidateProgram(handle)
		check( ProgramParameter.ValidateStatus )
	
	# add specific objects
	public def add(*shads as (Object)) as void:
		assert not linked
		blocks.Extend(shads)
		for sh in shads:
			GL.AttachShader(handle, sh.handle)	if sh
	# add object from library
	public def add(*names as (string)) as void:
		for s in names:
			add( Object.Load(s) )
	# link program
	public virtual def link() as void:
		#assert not linked
		linked = true
		GL.LinkProgram(handle)
		check( ProgramParameter.LinkStatus )
	# activate program
	public def bind() as void:
		assert linked
		if Current == self:
			return
		GL.UseProgram(handle)
		Current = self

	# assign vertex attribute slot
	public def attrib(index as byte, name as string) as void:
		assert index < kri.Ant.Inst.caps.vertexAttribs
		GL.BindAttribLocation(handle, index, name)
	public def attribAll(names as (string)) as void:
		for i in range(names.Length):
			attrib(i,names[i])
	# assign fragment output slot
	public def fragout(*names as (string)) as void:
		assert names.Length <= kri.Ant.Inst.caps.drawBuffers
		for i in range(names.Length):
			GL.BindFragDataLocation( handle, i, names[i] )
	# assign transform feedback
	public def feedback(sep as bool, *names as (string)) as void:
		tm = (TransformFeedbackMode.InterleavedAttribs,TransformFeedbackMode.SeparateAttribs)[sep]
		GL.TransformFeedbackVaryings( handle, names.Length, names, tm )

	# get uniform location by name
	public def getLocation(name as string) as int:
		assert linked
		return GL.GetUniformLocation(handle,name)
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
			GL.DetachShader( handle, sh.handle )	if sh
		blocks.Clear()
