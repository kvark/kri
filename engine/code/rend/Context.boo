namespace kri.rend

import System
import OpenTK.Graphics.OpenGL


# Rendering context class
public enum ActiveDepth:
	None
	With
	Only

internal enum DirtyLevel:
	None
	Target
	Depth


# Context passed to renders
public class Context:
	public final bitColor	as byte					# color storage
	public final bitDepth	as byte					# depth storage
	private final buf	as kri.frame.Buffer			# intermediate FBO
	private final last	as kri.frame.Screen			# final result
	private target		as kri.frame.Screen = null	# current result
	private dirty		as DirtyLevel				# dirty level
	private final iDep	as int						# depth attachment id

	[getter(Input)]
	private tInput	as kri.Texture	= null
	[getter(Depth)]
	private tDepth	as kri.Texture	= null
	public Aspect	as single:
		get: return buf.Width * 1f / buf.Height
	
	public Screen	as bool:
		get: return target == last
		set: target = (last if value else buf)
	public BufSamples	as byte:
		get: return buf.Samples
	
	state DepthTest
	state Multisample
	
	#Q: are we sure the writing/masking is enabled?
	public static def ClearDepth(val as single) as void:
		GL.ClearDepth(val)
		GL.Clear( ClearBufferMask.DepthBufferBit )
	public static def ClearStencil(val as int) as void:
		GL.ClearStencil(val)
		GL.Clear( ClearBufferMask.StencilBufferBit )
	public static def ClearColor(val as OpenTK.Graphics.Color4) as void:
		GL.ClearColor(val)
		GL.Clear( ClearBufferMask.ColorBufferBit )
	public static def ClearColor() as void:
		ClearColor( OpenTK.Graphics.Color4.Black )
	

	public def constructor(fs as kri.frame.Screen, ns as byte, bc as byte, bd as byte):
		tt = (TextureTarget.Texture2D, TextureTarget.Texture2DMultisample)[ns>0]
		buf = kri.frame.Buffer(ns,tt)
		bitColor,bitDepth = bc,bd
		target = last = fs
		iDep = (-1,-2)[bitDepth == 8]
		b = bc | bd
		assert not (b&0x7) and b<=48
	
	public def activeRead() as void:
		needColor(true)
		buf.dropMask()
		buf.activate(false)

	public def resize(w as int, h as int) as kri.frame.Screen:
		swapUnit(0,   tInput)	if Input
		swapUnit(iDep,tDepth)	if Depth
		buf.init(w,h)
		buf.resizeFrames()
		Input.InitMulti( buf.A[0].Format, buf.Samples, false, w,h,0 )	if Input
		return buf
	
	private def swapUnit(slot as int, ref tex as kri.Texture):
		t = buf.A[slot].Tex
		buf.A[slot].Tex = tex
		tex = t
	
	public def needDepth(dep as bool) as void:
		at = buf.A[iDep]
		assert not at.Tex or not tDepth
		if dep and not at.Tex:
			# need depth but don't have one
			if tDepth:
				at.Tex = tDepth
				tDepth = null
			else: buf.emitAuto(iDep,bitDepth)
		if not dep and at.Tex:
			# don't need it but it's there
			tDepth = at.Tex
			at.Tex = null

	public def needColor(col as bool) as void:
		if (col and not buf.A[0].Tex) or not (col or tInput):
			swapUnit(0,tInput)
		if (col and not buf.A[0].Tex):
			buf.emitAuto(0,bitColor)
		
	
	public static def SetDepth(offset as single, write as bool) as void:
		DepthTest = on = (not Single.IsNaN(offset))
		# set polygon offset
		return	if not on
		GL.DepthMask(write)
		cap = EnableCap.PolygonOffsetFill
		if offset:
			GL.PolygonOffset(offset,offset)
			GL.Enable(cap)
		else:	GL.Disable(cap)
	
	public def activate(toColor as bool, offset as single, toDepth as bool) as void:
		assert target
		if target == buf:
			buf.mask = (0,1)[toColor]
			needDepth( not Single.IsNaN(offset) )
			needColor(toColor)
		target.activate(true)
		SetDepth(offset,toDepth)
		dirty = (DirtyLevel.Depth, DirtyLevel.Target)[toColor]

	public def activate() as void:
		activate(true, Single.NaN, true)
	
	public def copy() as void:
		assert target != buf
		activate()		# draw to screen
		activeRead()	# read from buf
		buf.blit( ClearBufferMask.ColorBufferBit )
	
	public def apply(r as Basic) as void:
		# target always contains result
		if r.bInput: swapUnit(0,tInput)
		dirty = DirtyLevel.None
		r.process(self)	# action here!
		if dirty == DirtyLevel.Depth:	# restore mask
			if target == buf: buf.dropMask()
			else: GL.DrawBuffer( DrawBufferMode.Back )
		if dirty == DirtyLevel.None and r.bInput:
			swapUnit(0,tInput)
