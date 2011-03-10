namespace kri.rend

import System
import OpenTK.Graphics.OpenGL
import kri.buf

# Context passed to renders
public class Context:
	public	final	bitColor	as byte			# color storage
	public	final	bitDepth	as byte			# depth storage
	private	final	buf			= Holder()		# intermediate FBO
	private	final	last		as Frame		# final result
	private	target		as Frame	= null		# current result
	private	final	texTarget	as TextureTarget
	private final	nSamples	as byte

	public Input as Texture:
		get: return buf.at.color[0] as Texture
	public Depth as Texture:
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
		
	public Aspect	as single:
		get: # make sure FBO has color plane
			return buf.getInfo().Aspect
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
	
	public def resize(w as int, h as int) as Plane:
		if not Input:
			buf.at.color[0] = makeSurface()
		buf.resize(w,h)
		return buf.getInfo()

	public def makeSurface() as Texture:
		return Texture(
			target:texTarget, samples:nSamples,
			intFormat:FmColor[bitColor>>3] )

	
	public def needDepth(dep as bool) as void:
		return	if Depth or not dep
		# need depth but don't have one
		pf = (PixelFormat.DepthComponent,PixelFormat.DepthStencil)[bitDepth==8]
		Depth = t = makeSurface()
		t.pixFormat = pf
		t.intFormat = FmDepth[bitDepth>>3]
		tor = buf.at.color[0]
		t.init( tor.wid, tor.het )

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
	
	public def activate(ct as Basic.ColorTarget, offset as single, toDepth as bool) as void:
		assert target
		kri.Ant.Inst.params.activate( target.getInfo() )
		if target == buf:
			needDepth( not Single.IsNaN(offset) )
			buf.mask = (0,1)[ ct!=Basic.ColorTarget.None ]
			if ct == Basic.ColorTarget.New:
				t = buf.at.color[1]
				buf.at.color[1] = Input
				if not t:
					t = makeSurface()
					t.init( Input.wid, Input.het )
				buf.at.color[0] = t
		target.bind()
		SetDepth(offset,toDepth)
	
	public def activate(toNew as bool) as void:
		ct = (Basic.ColorTarget.Same,Basic.ColorTarget.New)[toNew]
		activate( ct, Single.NaN, true )

	public def blitTo(dest as Frame, what as ClearBufferMask) as void:
		buf.copyTo(dest,what)
	
	public def copy() as void:
		blitTo( target, ClearBufferMask.ColorBufferBit )
