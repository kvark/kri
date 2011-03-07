namespace kri.buf

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Container:
	public stencil	as Surface
	public depth	as Surface
	public color	as (Surface)
	public All	as Surface*:
		get: return (s	for s in ((stencil,depth) + color)	if s)
	public def constructor(num as byte):
		color = array[of Surface](num)
	public def clear() as void:
		stencil = depth = null
		for i in range(color.Length):
			color[i] = null


public class Target(Frame):
	private	old	= Container(4)
	public	at	= Container(4)
	
	private def addSurface(fa as FramebufferAttachment, ref cur as Surface, nex as Surface) as void:
		return	if cur==nex
		cur = nex
		nex = Render.Zero	if not nex
		nex.attachTo(fa)
	
	public def getSamples() as int:
		sm = -1
		for sf in at.All:
			if sm<0:
				sm = sf.samples
			elif sm!=sf.samples:
				return -1
		return sm
	
	public def getDimensions() as Drawing.Size:
		v = Drawing.Size(1<<30,1<<30)
		for sf in at.All:
			v.Width		= Math.Min( v.Width,	cast(int,sf.wid) )
			v.Height	= Math.Min( v.Height,	cast(int,sf.het) )
		return v
	
	public def activate(mask as byte) as void:
		# bind with viewport
		bind()
		GL.Viewport( getDimensions() )
		assert getSamples()>=0
		# update surfaces
		if 'ds':
			addSurface( FramebufferAttachment.StencilAttachment,	old.stencil,	at.stencil )
			addSurface( FramebufferAttachment.DepthAttachment,		old.depth,		at.depth )
		for i in range( old.color.Length ):
			addSurface( FramebufferAttachment.ColorAttachment0+i,	old.color[i],	at.color[i] )
		# check
		CheckStatus()
		# set mask
		drawList = List[of DrawBuffersEnum](
			DrawBuffersEnum.ColorAttachment0+i
			for i in range(4)	if (mask>>i)&1)
		GL.DrawBuffers( drawList.Count, drawList.ToArray() )
	
	public def resize(wid as uint, het as uint) as void:
		for sf in at.All:
			sf.init(wid,het)
	
	public def markDirty() as void:
		old.clear()