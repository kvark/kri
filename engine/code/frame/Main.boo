namespace kri.frame

import OpenTK.Graphics.OpenGL


#---------	Basic Framebuffer container	---------#

public class Array:
	protected dirtyPort = true	# need to update Viewport
	[getter(Width)]
	private wid as uint = 0
	[getter(Height)]
	private het as uint = 0

	public def init(x as uint, y as uint) as void:
		dirtyPort = true
		wid,het = x,y
	public static def Clear(depth as bool) as void:
		mask = ClearBufferMask.ColorBufferBit
		if depth:
			mask |= ClearBufferMask.DepthBufferBit
		GL.Clear(mask)


#---------	FB with offset, clear & activate	---------#

public class Screen(Array):
	private ofx as int = 0
	private ofy as int = 0
	[Getter(Extract)]
	private final id as int
	
	public def constructor():
		id = 0
	protected def constructor(newid as int):
		id = newid
	
	public def offset(x as int, y as int) as void:
		dirtyPort = true
		ofx,ofy = x,y
	public def bindRead() as void:
		GL.BindFramebuffer( FramebufferTarget.ReadFramebuffer, id )
	
	public virtual def activate() as void:
		GL.BindFramebuffer( FramebufferTarget.Framebuffer, id )
		#return if not dirtyPort
		GL.Viewport(ofx,ofy, ofx+Width,ofy+Height)
		dirtyPort = false
