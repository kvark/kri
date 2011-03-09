namespace kri.rend

import System
import OpenTK.Graphics.OpenGL
import kri.buf

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
	public	final	bitColor	as byte			# color storage
	public	final	bitDepth	as byte			# depth storage
	private	final	buf			= Holder()		# intermediate FBO
	private	final	last		as Frame		# final result
	private	target	as Frame = null			# current result
	private	dirty	= DirtyLevel.None		# dirty level
	private	final	texTarget	as TextureTarget
	private final	nSamples	as byte

	[getter(Input)]
	private tInput	as kri.buf.Texture	= null
	[getter(Depth)]
	private tDepth	as kri.buf.Texture	= null
	public Aspect	as single:
		get: return buf.getInfo().Aspect
	public Info		as kri.buf.Plane:
		get: return target.getInfo()
	
	public Screen	as bool:
		get: return target == last
		set: target = (last if value else buf)
	
	state DepthTest
	state Multisample
	
	public static def Init() as void:
		GL.Enable( EnableCap.CullFace )
		GL.CullFace( CullFaceMode.Back )
		GL.ClearDepth(1f)
		GL.DepthRange(0f,1f)
		GL.DepthFunc( DepthFunction.Lequal )
	
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
	
	public static final FmColor	= (of PixelInternalFormat:
		PixelInternalFormat.Rgba,		#0 - standard
		PixelInternalFormat.Rgba8,		#8
		PixelInternalFormat.Rgba16,		#16
		PixelInternalFormat.Rgba16f,	#24
		PixelInternalFormat.Rgba32f)	#32
	public static final FmDepth	= (of PixelInternalFormat:
		PixelInternalFormat.DepthComponent,		#0 - standard
		PixelInternalFormat.Depth24Stencil8,	#8
		PixelInternalFormat.DepthComponent16,	#16
		PixelInternalFormat.DepthComponent24,	#24
		PixelInternalFormat.DepthComponent32)	#32
	

	public def constructor(fs as Frame, ns as byte, bc as byte, bd as byte):
		texTarget = (TextureTarget.Texture2D, TextureTarget.Texture2DMultisample)[ns>0]
		nSamples,bitColor,bitDepth = ns,bc,bd
		target = last = fs
		b = bc | bd
		assert b<=48 and not (b&0x7)
	
	public def swapInput() as void:
		s = buf.at.color[0]
		buf.at.color[0] = tInput
		tInput = s as Texture
	
	public def resize(w as int, h as int) as Plane:
		needColor(true)
		# make sure depth is in
		if Depth:
			if Depth.pixFormat == PixelFormat.DepthStencil		and not buf.at.stencil:
				buf.at.stencil = Depth
				tDepth = null
			if Depth.pixFormat == PixelFormat.DepthComponent	and not buf.at.depth:
				buf.at.depth = Depth
				tDepth = null
		# do it
		buf.resize(w,h)
		# don't forget about second texture
		if Input:
			t = buf.at.color[0] as Texture
			Input.samples = nSamples
			Input.intFormat = t.intFormat
			Input.init(w,h)
		return buf.getInfo()
	
	private BufDepth as Texture:
		get:
			st = buf.at.stencil as Texture
			return st	if st and st.pixFormat == PixelFormat.DepthStencil
			return buf.at.depth as Texture
		set:
			if not value:
				buf.at.depth = buf.at.stencil = null
			elif value.pixFormat == PixelFormat.DepthStencil:
				buf.at.stencil = value
			else:
				buf.at.depth = value
	
	public def needDepth(dep as bool) as void:
		bd = BufDepth
		assert not bd or not Depth
		if dep and not bd:
			# need depth but don't have one
			if tDepth:
				BufDepth = tDepth
				tDepth = null
			else:
				pf = (PixelFormat.DepthComponent,PixelFormat.DepthStencil)[bitDepth==8]
				BufDepth = t = Texture( target:texTarget, samples:nSamples,
					intFormat:FmDepth[bitDepth>>3], pixFormat:pf )
				tor = (of Surface: buf.at.color[0],tInput)[tInput!=null]
				t.init( tor.wid, tor.het )
		if not dep and bd:
			# don't need it but it's there
			tDepth = bd
			BufDepth = null

	public def needColor(col as bool) as void:
		if (col and not buf.at.color[0]) or not (col or Input):
			swapInput()
		if (col and not buf.at.color[0]):
			buf.at.color[0] = Texture(
				target:texTarget, samples:nSamples,
				intFormat:FmColor[bitColor>>3] )
	
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
		kri.Ant.Inst.params.activate( target.getInfo() )
		if target == buf:
			buf.mask = (0,1)[toColor]
			needDepth( not Single.IsNaN(offset) )
			needColor(toColor)
		target.bind()
		SetDepth(offset,toDepth)
		dirty = (DirtyLevel.Depth, DirtyLevel.Target)[toColor]

	public def activate() as void:
		activate(true, Single.NaN, true)

	public def blitTo(dest as Frame, what as ClearBufferMask) as void:
		needColor(true)	if what & ClearBufferMask.ColorBufferBit
		needDepth(true)	if what & ClearBufferMask.DepthBufferBit
		buf.copyTo(dest,what)
	
	public def copy() as void:
		blitTo( target, ClearBufferMask.ColorBufferBit )
	
	public def apply(r as Basic) as void:
		# target always contains result
		swapInput()	if r.bInput
		dirty = DirtyLevel.None
		r.process(self)	# action here!
		if dirty == DirtyLevel.Depth:	# restore mask
			if target == buf: buf.dropMask()
			else: GL.DrawBuffer( DrawBufferMode.Back )
		if dirty == DirtyLevel.None and r.bInput:
			swapInput()
