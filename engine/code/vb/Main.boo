namespace kri.vb

import System
import OpenTK.Graphics.OpenGL


#-----------------------
#	BUFFER OBJECT
#-----------------------

public class Object:
	public	final handle	as uint
	[getter(Ready)]
	private	filled			as bool	= false
	public	static Bind[targ as BufferTarget] as Object:
		set: GL.BindBuffer( targ, (value.handle if value else cast(uint,0)) )
	public	static Index as Object:
		set: Bind[BufferTarget.ElementArrayBuffer] = value
	public	static Vertex as Object:
		set: Bind[BufferTarget.ArrayBuffer] = value
	public	static final DefTarget	= BufferTarget.ArrayBuffer
	# creating
	public def constructor():
		tmp = 0
		GL.GenBuffers(1,tmp)
		handle = tmp
	def destructor():
		tmp = handle
		kri.Help.safeKill({ GL.DeleteBuffers(1,tmp) })
	# binding
	public def bind() as void:
		Bind[DefTarget] = self
	# filling
	private static def GetHint(dyn as bool) as BufferUsageHint:
		return (BufferUsageHint.StreamDraw if dyn else BufferUsageHint.StaticDraw)
	public def init(size as uint) as void:
		bind()
		GL.BufferData(DefTarget, IntPtr(size), IntPtr.Zero, GetHint(true))
		filled = true
	public def init[of T(struct)](ptr as (T), dyn as bool) as void:
		bind()
		GL.BufferData(DefTarget, IntPtr(ptr.Length * kri.Sizer[of T].Value), ptr, GetHint(dyn))
		filled = true
	# mapping
	public def tomap(ba as BufferAccess) as IntPtr:
		bind()
		return GL.MapBuffer(DefTarget,ba)
	public def unmap() as bool:
		return GL.UnmapBuffer(DefTarget)
	[ext.spec.Method(( byte,short,single ))]
	[ext.RemoveSource]
	public def read[of T(struct)](ar as (T)) as void:
		buf = tomap( BufferAccess.ReadOnly )
		Marshal.Copy( buf, ar, 0, ar.Length )
		unmap()
