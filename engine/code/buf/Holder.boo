namespace kri.buf

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Container:
	public stencil	as Surface
	public depth	as Surface
	public color	as (Surface)
	public All		as Surface*:
		get: return (s	for s in ((stencil,depth) + color)	if s)
	public def constructor(num as byte):
		color = array[of Surface](num)
	public def clear() as void:
		stencil = depth = null
		for i in range(color.Length):
			color[i] = null


public class Holder(Frame):
	private	old		= Container(4)
	public	at		= Container(4)
	private oldMask	= -1
	public	mask	= 0
	
	public def dropMask() as void:
		oldMask = -1
	
	private def addSurface(fa as FramebufferAttachment, ref cur as Surface, nex as Surface) as void:
		return	if cur==nex
		cur = nex
		(Render.Zero,nex)[nex!=null].attachTo(fa)
	
	public def getSamples() as int:
		sm = -1
		for sf in at.All:
			if sm<0:
				sm = sf.samples
			elif sm!=sf.samples:
				return -1
		return sm
	
	public override def getInfo() as Plane:
		sm = getSamples()
		return null	if sm<0
		pl = Plane( samples:sm, wid:1<<30, het:1<<30 )
		for sf in at.All:
			pl.wid	= Math.Min( pl.wid,	sf.Width )
			pl.het	= Math.Min( pl.het,	sf.Height )
		return pl
	
	public override def bind() as void:
		# bind with viewport
		super()
		assert getSamples()>=0
		# update surfaces
		if 'ds':
			addSurface( FramebufferAttachment.DepthStencilAttachment,	old.stencil,	at.stencil )
			addSurface( FramebufferAttachment.DepthAttachment,			old.depth,		at.depth )
		for i in range( old.color.Length ):
			surface = old.color[i]	# Boo bug workaround
			addSurface( FramebufferAttachment.ColorAttachment0+i,		surface,	at.color[i] )
			old.color[i] = surface
		# check
		CheckStatus()
		# set mask
		if mask != oldMask:
			assert mask>=0
			drawList = List[of DrawBuffersEnum](
				DrawBuffersEnum.ColorAttachment0+i
				for i in range(4)	if (mask>>i)&1)
			GL.DrawBuffers( drawList.Count, drawList.ToArray() )
			oldMask = mask
	
	private override def getReadMode() as ReadBufferMode:
		return ReadBufferMode.ColorAttachment0

	public def resize(wid as uint, het as uint) as void:
		for sf in at.All:
			sf.init(wid,het)
	
	public def markDirty() as void:
		old.clear()