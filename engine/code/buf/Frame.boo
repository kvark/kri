namespace kri.buf

import System
import System.Runtime.InteropServices
import OpenTK.Graphics.OpenGL


public class Frame:
	private final	handle	as uint
	
	# construction
	
	public static def CheckStatus() as void:
		status = GL.CheckFramebufferStatus( FramebufferTarget.Framebuffer )
		assert status = FramebufferErrorCode.FramebufferComplete
	
	public def constructor():
		id = -1
		GL.GenFramebuffers(1,id)
		handle = id
	
	protected def constructor(manId as uint):
		handle = manId

	def destructor():
		if not handle:
			return
		kri.Help.safeKill() do:
			tmp as int = handle
			GL.DeleteFramebuffers(1,tmp)
	
	# size parameters
	
	public abstract def getInfo() as Plane:
		pass
	
	public def getDimensions() as Drawing.Size:
		pl = getInfo()
		assert pl
		return Drawing.Size( pl.wid, pl.het )
	
	public virtual def getOffsets() as Drawing.Point:
		return Drawing.Point(0,0)
	
	public def getRect(rez as Drawing.Rectangle) as Plane:
		pl = getInfo()
		assert pl
		rez.Location = getOffsets()
		rez.Size = Drawing.Size( pl.wid, pl.het )
		return pl

	# binding
	
	public virtual def bind() as void:
		GL.BindFramebuffer( FramebufferTarget.Framebuffer, handle )
		GL.Viewport( getOffsets(), getDimensions() )
	
	private abstract def getReadMode() as ReadBufferMode:
		pass
	
	public def bindRead(color as bool) as void:
		GL.BindFramebuffer( FramebufferTarget.ReadFramebuffer, handle )
		rm = cast(ReadBufferMode,0)
		if color:
			rm = getReadMode()
		GL.ReadBuffer(rm)
	
	public def copyTo(fr as Frame, what as ClearBufferMask) as void:
		assert self != fr
		bind()	# update attachments
		fr.bind()
		GL.BindFramebuffer( FramebufferTarget.ReadFramebuffer, handle )
		bindRead( what & ClearBufferMask.ColorBufferBit != 0 )
		r0 = r1 = Drawing.Rectangle()
		i0 = getRect(r0)
		i1 = fr.getRect(r1)
		assert i0.isCompatible(i1)
		GL.BlitFramebuffer(
			r0.Left, r0.Top, r0.Right, r0.Bottom,
			r1.Left, r1.Top, r1.Right, r1.Bottom,
			what, BlitFramebufferFilter.Linear )
	
	# reading
	
	public def readRaw[of T(struct)](fm as PixelFormat, rect as Drawing.Rectangle, ptr as IntPtr) as void:
		noColorFormats = (PixelFormat.DepthComponent, PixelFormat.DepthStencil, PixelFormat.StencilIndex)
		type = Texture.GetPixelType(T)
		bindRead( fm not in noColorFormats )
		GL.ReadPixels( rect.Left, rect.Top, rect.Width, rect.Height, fm, type, ptr )

	public def read[of T(struct)](fm as PixelFormat, rect as Drawing.Rectangle) as (T):
		data = array[of T](rect.Width * rect.Height)
		ptr = GCHandle.Alloc( data, GCHandleType.Pinned )
		readRaw[of T]( fm, rect, ptr.AddrOfPinnedObject() )
		return data



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
