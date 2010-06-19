namespace kri.vb

import System
import OpenTK.Graphics.OpenGL


#-----------------------
#	VERTEX ARRAY
#-----------------------

public class Array:
	public static final Default	= Array(0)
	public final id	as int
	public def constructor():
		tmp = 0
		GL.GenVertexArrays(1,tmp)
		id = tmp
	private def constructor(xid as int):
		id = xid
	def destructor():
		tmp = id
		kri.safeKill({ GL.DeleteVertexArrays(1,tmp) })
	public def bind() as void:
		GL.BindVertexArray(id)
	public static def unbind() as void:
		GL.BindVertexArray(0)


#-----------------------
#	BUFFER PROXY
#-----------------------

public class Proxy:
	public final target	as BufferTarget
	# creating
	public def constructor(targ as BufferTarget):
		target = targ
	public def bind(v as Object) as void:
		GL.BindBuffer(target, ( v.Extract if v else cast(uint,0) ))


#-----------------------
#	BUFFER OBJECT
#-----------------------

public class Object(Proxy):
	[getter(Extract)]
	private final id		as uint
	[getter(Ready)]
	private filled			as bool	= false
	# creating
	public def constructor(targ as BufferTarget):
		super(targ)
		tmp = 0
		GL.GenBuffers(1,tmp)
		id = tmp
	def destructor():
		tmp = id
		kri.safeKill({ GL.DeleteBuffers(1,tmp) })
	# binding
	public def bind() as void:
		bind(self)
	public def unbind() as void:
		bind(null)
	# filling
	private def getHint(dyn as bool) as BufferUsageHint:
		return (BufferUsageHint.StreamDraw if dyn else BufferUsageHint.StaticDraw)
	public def init(size as uint) as void:
		bind()
		GL.BufferData(target, IntPtr(size), IntPtr.Zero, getHint(true))
		filled = true
	public def init[of T(struct)](ptr as (T), dyn as bool) as void:
		bind()
		GL.BufferData(target, IntPtr(ptr.Length * kri.Sizer[of T].Value), ptr, getHint(dyn))
		filled = true
	# mapping
	public def tomap(ba as BufferAccess) as IntPtr:
		bind()
		return GL.MapBuffer(target,ba)
	public def unmap() as bool:
		return GL.UnmapBuffer(target)
	[ext.spec.Method(( byte,short,single ))]
	[ext.RemoveSource]
	public def read[of T(struct)](ar as (T)) as void:
		ar[0] = Single.Epsilon	# compiler hint
		buf = tomap( BufferAccess.ReadOnly )
		Marshal.Copy( buf, ar, 0, ar.Length )
		unmap()


#-----------------------
#	CUSTOM OBJECTS
#-----------------------

public class Index(Object):
	public def constructor():
		super( BufferTarget.ElementArrayBuffer )

public class Pack(Object):
	public def constructor():
		super( BufferTarget.PixelPackBuffer )
