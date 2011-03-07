namespace kri.buf

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


public struct Container:
	public stencil	as Surface
	public depth	as Surface
	public color	as (Surface)
	public All	as (Surface):
		get: return (stencil,depth) + color
	public def constructor(num as byte):
		color = array[of Surface](num)


public class Target(Frame):
	private	oldCont	= Container(4)
	public	newCont	= Container(4)
	
	private def addSurface(fa as FramebufferAttachment, ref cur as Surface, nex as Surface) as void:
		return	if cur==nex
		(Render.Zero,nex)[nex and nex.active].attachTo(fa)
		cur = nex
	
	public def getSamples() as int:
		sm = List[of int](sf.samples	for sf in newCont.All	if sf.active)
		pred = def(s as int) as bool:
			return s != sm[0]
		return (sm[0],-1)[ sm.Exists(pred) ]
	
	public def getDimensions() as Drawing.Size:
		s = Drawing.Size(1<<30,1<<30)
		for sf in newCont.All:
			continue	if not sf.active
			s.Width		= Math.Min( s.Width,	cast(int,sf.wid) )
			s.Height	= Math.Min( s.Height,	cast(int,sf.het) )
		return s
	
	public def use() as void:
		# bind with viewport
		bind()
		GL.Viewport( getDimensions() )
		assert getSamples()>=0
		# update surfaces
		if 'ds':
			addSurface( FramebufferAttachment.StencilAttachment,	oldCont.stencil,	newCont.stencil )
			addSurface( FramebufferAttachment.DepthAttachment,		oldCont.depth,		newCont.depth )
		for i in range( oldCont.color.Length ):
			addSurface( FramebufferAttachment.ColorAttachment0+i,	oldCont.color[i],	newCont.color[i] )
		# check
		CheckStatus()
