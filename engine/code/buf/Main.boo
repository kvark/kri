namespace kri.buf

import OpenTK.Graphics.OpenGL


public class Surface:
	public wid		as uint	= 0
	public het		as uint	= 0
	public samples	as byte	= 0
	public active	as bool	= true
	# attache to a framebuffer
	public abstract def attachTo(fa as FramebufferAttachment) as void:
		pass
	# bind on its own
	public abstract def bind() as void:
		pass
	# retrieve GL state
	public abstract def syncBack() as void:
		pass


public class Frame:
	public def bind() as void:
		pass


public struct Container:
	public stencil	as Surface
	public depth	as Surface
	public color	as (Surface)
	public All	as (Surface):
		get: return (stencil,depth) + color
	public def constructor(num as byte):
		color = array[of Surface](num)


public class Target(Frame):
	private cr	= Container(4)
	public at	= Container(4)
	
	private def addSurface(fa as FramebufferAttachment, ref cur as Surface, nex as Surface) as void:
		return	if cur==nex
		(Render.Zero,nex)[nex and nex.active].attachTo(fa)
		cur = nex
	
	private final static Colors = (of FramebufferAttachment:
		FramebufferAttachment.ColorAttachment0,
		FramebufferAttachment.ColorAttachment1,
		FramebufferAttachment.ColorAttachment2,
		FramebufferAttachment.ColorAttachment3)
	
	public def checkSamples() as bool:
		samples=-1
		for sf in at.All:
			if sf and sf.active:
				if samples<0:
					samples = sf.samples
				return false	if samples != sf.samples
		return true
	
	public def use() as void:
		bind()
		assert checkSamples()
		addSurface( FramebufferAttachment.StencilAttachment, cr.stencil, at.stencil )
		addSurface( FramebufferAttachment.DepthAttachment, cr.depth, at.depth )
		for i in range(cr.color.Length):
			addSurface( Colors[i], cr.color[i], at.color[i] )
