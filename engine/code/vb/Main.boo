namespace kri.vb

import System
import System.Collections.Generic
import System.Runtime.InteropServices
import OpenTK.Graphics.OpenGL

#---------

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


public class Proxy:
	protected final target	as BufferTarget
	# creating
	public def constructor(targ as BufferTarget):
		target = targ
	public def bind(v as Object) as void:
		GL.BindBuffer(target, (v.Extract if v else 0))


public class Object(Proxy):
	[getter(Extract)]
	private final id		as int
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
		GL.BindBuffer(target,id)
	public def unbind() as void:
		GL.BindBuffer(target,0)
	# filling
	private def getHint(dyn as bool) as BufferUsageHint:
		return (BufferUsageHint.StreamDraw if dyn else BufferUsageHint.StaticDraw)
	public def init(size as int) as void:
		bind()
		GL.BufferData(target, IntPtr(size), IntPtr.Zero, getHint(true))
		filled = true
	public def init[of T(struct)](ptr as (T), dyn as bool) as void:
		bind()
		GL.BufferData(target, IntPtr(ptr.Length * kri.Sizer[of T].Value), ptr, getHint(dyn))
		filled = true
	# mapping
	public def map(ba as BufferAccess) as IntPtr:
		bind()
		return GL.MapBuffer(target,ba)
	public def unmap() as bool:
		return GL.UnmapBuffer(target)
	[ext.spec.Method(byte,short,single)]
	[ext.RemoveSource]
	public def read[of T(struct)](ar as (T)) as void:
		buf = map(BufferAccess.ReadOnly)
		Marshal.Copy(buf, ar, 0, ar.Length)
		unmap()


public class Attrib(Object):
	public final semantics	= List[of attr.Info]()
	public def constructor():
		super(BufferTarget.ArrayBuffer)
	
	public def unitSize() as int:
		rez = 0
		for a in semantics:
			rez += a.fullSize()
		return rez
	
	public def initAll(num as int) as void:
		off,total = 0,unitSize()
		init(num * total)
		semantics.ForEach() do(ref at as attr.Info):
			push(at, off, total)
			off += at.fullSize()

	private def push(ref at as attr.Info, off as int, total as int) as void:
		GL.EnableVertexAttribArray( at.slot )
		if at.integer: #TODO: use proper enum
			GL.VertexAttribIPointer(at.slot, at.size,
				cast(VertexAttribIPointerType,cast(int,at.type)),
				total, IntPtr(off))
		else:
			GL.VertexAttribPointer(at.slot, at.size,
				at.type, false, total, off)
				
	private def push(ref at as attr.Info, off as int) as void:
		push(at, off, unitSize())
		
	private def push(ref ain as attr.Info) as void:
		off = 0
		for at in semantics:
			break	if at == ain
			off += at.fullSize()
		push(ain, off)

	public def attrib(id as int) as bool:
		off = 0
		return semantics.Exists() do(ref at as attr.Info):
			if at.slot != id:
				off += at.fullSize()
				return false	
			bind()
			push(at,off)
			return true
			
	public def attribFirst() as void:
		bind()
		ai = semantics[0]
		push(ai,0)
	
	public def attribFake(slot as uint) as void:
		bind()
		ai = semantics[0]
		ai.slot = slot
		push(ai,0)


public class Index(Object):
	public def constructor():
		super(BufferTarget.ElementArrayBuffer)