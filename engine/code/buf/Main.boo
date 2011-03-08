namespace kri.buf

import System
import OpenTK.Graphics.OpenGL


public class Plane:
	public samples	as byte	= 0
	public wid		as uint	= 0
	public het		as uint	= 0
	# attributes
	public virtual Width as uint:
		get: return wid
	public virtual Height as uint:
		get: return het
	public Aspect	as single:
		get: return wid*1f / het
	public Size		as uint:
		get: return Width * Height * Math.Max(samples,0)
	# methods
	public def isCompatible(pl as Plane) as bool:
		if samples!=pl.samples:
			# only MS resolution is possible
			if samples*pl.samples:
				return false
			if wid!=pl.wid or het!=pl.het:
				return false
		return true


public class Surface(Plane):
	public name		as string	= ''
	# attache to a framebuffer
	public abstract def attachTo(fa as FramebufferAttachment) as void:
		pass
	# bind on its own
	public abstract def bind() as void:
		pass
	# allocate contents
	public abstract def init() as void:
		pass
	public def init(w as uint, h as uint) as void:
		wid,het = w,h
		init()
	# retrieve GL state
	public abstract def syncBack() as void:
		pass



public class Frame:
	private final	hardId	as uint
	
	public static def CheckStatus() as void:
		status = GL.CheckFramebufferStatus( FramebufferTarget.Framebuffer )
		assert status = FramebufferErrorCode.FramebufferComplete
	
	public def constructor():
		id = -1
		GL.GenFramebuffers(1,id)
		hardId = id
	
	protected def constructor(manId as uint):
		hardId = manId

	def destructor():
		return	if not hardId
		kri.Help.safeKill() do:
			tmp as int = hardId
			GL.DeleteFramebuffers(1,tmp)
	
	public abstract def getInfo() as Plane:
		pass
	public def getDimensions() as Drawing.Size:
		pl = getInfo()
		return Drawing.Size( pl.wid, pl.het )
	public virtual def getOffsets() as Drawing.Point:
		return Drawing.Point(0,0)

	public virtual def bind() as void:
		GL.BindFramebuffer( FramebufferTarget.Framebuffer, hardId )
		GL.Viewport( getOffsets(), getDimensions() )
	
	private abstract def getReadMode() as ReadBufferMode:
		pass
	
	public def bindRead(color as bool) as void:
		GL.BindFramebuffer( FramebufferTarget.ReadFramebuffer, hardId )
		rm = cast(ReadBufferMode,0)
		rm = getReadMode()	if color
		GL.ReadBuffer(rm)
	
	public def copyTo(fr as Frame, what as ClearBufferMask) as void:
		assert self != fr
		bind()	# update attachments
		fr.bind()
		GL.BindFramebuffer( FramebufferTarget.ReadFramebuffer, hardId )
		bindRead( what & ClearBufferMask.ColorBufferBit != 0 )
		i0 = getInfo()
		p0 = getOffsets()
		i1 = fr.getInfo()
		p1 = fr.getOffsets()
		assert i0.isCompatible(i1)
		GL.BlitFramebuffer(
			p0.X,p0.Y,i0.wid,i0.het,
			p1.X,p1.Y,i1.wid,i1.het,
			what, BlitFramebufferFilter.Linear )


public class Screen(Frame):
	public final plane	= Plane()
	public ofx	= 0
	public ofy	= 0
	
	public def constructor():
		super(0)
	public override def getInfo() as Plane:
		return plane
	public override def getOffsets() as Drawing.Point:
		return Drawing.Point(ofx,ofy)
	private override def getReadMode() as ReadBufferMode:
		return ReadBufferMode.Back
