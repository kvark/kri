namespace kri.buf

import OpenTK.Graphics.OpenGL


public class Surface:
	public wid		as uint	= 0
	public het		as uint	= 0
	public samples	as byte	= 0
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
	
	private def constructor(manId as uint):
		hardId = manId
	public static final	Zero	= Frame(0)

	def destructor():
		return	if not hardId
		kri.Help.safeKill() do:
			tmp as int = hardId
			GL.DeleteFramebuffers(1,tmp)

	public def bind() as void:
		GL.BindFramebuffer( FramebufferTarget.Framebuffer, hardId )
