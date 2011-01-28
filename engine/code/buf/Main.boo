namespace kri.buf

import System
import OpenTK.Graphics.OpenGL


public class Surface:
	public wid		as uint
	public het		as uint
	public samples	as byte
	public active	as bool
	public abstract def bindTo(fa as FramebufferAttachment) as void:
		pass


public class Render(Surface):
	private final hardId	as uint
	public def constructor():
		hardId = 0
	public override def bindTo(fa as FramebufferAttachment) as void:
		GL.FramebufferRenderbuffer( FramebufferTarget.Framebuffer, fa, RenderbufferTarget.Renderbuffer, hardId )


public class Texture(Surface):
	private final hardId	as uint
	public def constructor():
		hardId = 0
	public override def bindTo(fa as FramebufferAttachment) as void:
		GL.FramebufferTexture2D( FramebufferTarget.Framebuffer, fa, TextureTarget.Texture2D, hardId, 0 )



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
		if nex and nex.active:
			nex.bindTo(fa)
		else:
			GL.FramebufferRenderbuffer( FramebufferTarget.Framebuffer, fa, RenderbufferTarget.Renderbuffer, 0 )
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
