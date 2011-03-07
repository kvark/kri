namespace kri.frame

import OpenTK.Graphics.OpenGL


internal static class Fm:
	public final bad		= PixelInternalFormat.Alpha
	public final stencil	= PixelInternalFormat.Depth24Stencil8
	public final depth	= (of PixelInternalFormat:
		PixelInternalFormat.DepthComponent,
		PixelInternalFormat.Depth24Stencil8,
		PixelInternalFormat.DepthComponent16,
		PixelInternalFormat.DepthComponent24,
		PixelInternalFormat.DepthComponent32
	)
	public final color	= (of PixelInternalFormat:
		PixelInternalFormat.Rgba,
		PixelInternalFormat.Rgba8,
		PixelInternalFormat.Rgba16f,
		bad,
		PixelInternalFormat.Rgba32f
	)
	public final index	= (of PixelInternalFormat:
		bad,
		PixelInternalFormat.R8,
		PixelInternalFormat.R16,
		bad,bad
	)
	public final index2	= (of PixelInternalFormat:
		bad,
		PixelInternalFormat.Rg8,
		PixelInternalFormat.Rg16,
		bad,bad
	)


#---------	FB lazy attachment management	---------#

public class Buffer(Screen):
	public enum Class:
		Color
		Depth
		Stencil
		Index
		Index2
		Other
		# auxilary methods for init
	private static def Fi2format(fi as PixelInternalFormat) as PixelFormat:
		return PixelFormat.DepthStencil		if fi == Fm.stencil
		return PixelFormat.DepthComponent	if fi in Fm.depth
		return PixelFormat.Red				if fi in Fm.index
		return PixelFormat.Rg				if fi in Fm.index2
		return PixelFormat.Rgba
	private static def Fi2type(fi as PixelInternalFormat) as PixelType:
		return PixelType.UnsignedInt248	if fi == Fm.stencil
		return PixelType.UnsignedByte	if fi in (Fm.color[:2] + Fm.index[:2] + Fm.index2[:2])
		return PixelType.UnsignedShort	if fi in ( Fm.index[2], Fm.index2[2] )
		return PixelType.UnsignedInt	if fi in ( Fm.index[4], Fm.index2[4] )
		return PixelType.Float
	
	public static def AskFormat(cl as Class, bits as uint) as PixelInternalFormat:
		d = bits>>3
		return Fm.color[d]	if cl == Class.Color
		return Fm.depth[d]	if cl == Class.Depth
		return Fm.stencil	if cl == Class.Stencil
		return Fm.index[d]	if cl == Class.Index
		return Fm.index2[d]	if cl == Class.Index2
		return Fm.bad
	
	public mask		as uint = 1		# desired draw mask
	private oldMask	as uint = 0		# active mask
	private static final badMask	as uint = 100	# bad mask
	[Getter(Samples)]
	protected samples		as byte				# samples count
	public fixedSampleLoc	as bool	= false
	public final texTarget	as TextureTarget	# texture target
	
	protected final at = (			# attachment controllers
		Unit(FramebufferAttachment.DepthStencilAttachment),
		Unit(FramebufferAttachment.DepthAttachment),
		Unit(FramebufferAttachment.ColorAttachment0),
		Unit(FramebufferAttachment.ColorAttachment1),
		Unit(FramebufferAttachment.ColorAttachment2),
		Unit(FramebufferAttachment.ColorAttachment3),
	)
	protected static FBASE	= 2		# color attachments offset
	public A[target as int] as Unit:
		get: return at[target+FBASE]
	
	public def constructor(nsam as byte, tg as TextureTarget):
		assert 4 <= kri.Ant.Inst.caps.colorAttaches
		tmp = 0
		GL.GenFramebuffers(1,tmp)
		super(tmp)
		dropMask()
		samples = nsam
		texTarget = tg
	
	public def constructor():
		self(0, TextureTarget.Texture2D )
			
	def destructor():
		tmp = Extract
		kri.Help.safeKill({ GL.DeleteFramebuffers(1,tmp) })
	
	public static def Check(target as FramebufferTarget) as void:
		status = GL.CheckFramebufferStatus( target )
		assert status == FramebufferErrorCode.FramebufferComplete
	
	
	# -------- CREATION ROUTINES ---------- #
	
	public def emit(id as int, pif as PixelInternalFormat) as kri.buf.Texture:
		t = A[id].Tex = kri.buf.Texture( target:texTarget )
		A[id].dFormat.Value = pif
		return t
	
	public def emit(id as int, cl as Class, bits as byte) as kri.buf.Texture:
		return emit( id, AskFormat(cl,bits) )
	
	public def emitAuto(id as int, bits as byte) as kri.buf.Texture:
		cl = Class.Color
		if id==-2:	cl = Class.Stencil
		if id==-1:	cl = Class.Depth
		return emit( id, cl, bits )
	
	public def emitArray(num as int) as kri.buf.Texture:
		tex = kri.buf.Texture( target:TextureTarget.Texture2DArray )
		for i in range(num):
			A[i].Tex = tex
			A[i].Layer = i
		mask = (1<<num) - 1
		return tex	

	# -------- AUXILARY ROUTINES ---------- #
	
	public def blit(what as ClearBufferMask) as void:
		GL.BlitFramebuffer(0,0,Width,Height,0,0,Width,Height,
			what, BlitFramebufferFilter.Nearest )
	
	public def blit(to as Screen) as void:
		assert Width==to.Width or not samples
		activate(false)
		to.activate(true)
		GL.BlitFramebuffer( 0,0,Width,Height, 0,0,to.Width,to.Height,
			ClearBufferMask.ColorBufferBit, BlitFramebufferFilter.Linear )
	
	public def read(pf as PixelFormat, pt as PixelType) as void:
		activate(false)
		GL.ReadPixels(0,0,Width,Height, pf,pt, System.IntPtr.Zero)
		
	public def dropMask() as void:
		oldMask = badMask
	
	public def resizeFrames() as void:
		for a in at:
			continue	if not a.Tex
			a.Tex.intFormat = a.Format
			a.Tex.samples = samples
			a.Tex.init(Width,Height)
			a.dFormat.clean()
	public def resizeFrames(nsam as byte) as void:
		samples = nsam
		resizeFrames()
	
	
	# -------- STATE UPDATE ROUTINES ---------- #
	
	public def updateMask(draw as bool) as void:
		return	if mask == oldMask
		if draw:
			dar = List[of DrawBuffersEnum]()
			for k in range( at.Length-FBASE ):
				if mask & (1<<k) and A[k].Tex:
					dar.Add( DrawBuffersEnum.ColorAttachment0 + k )
			if dar.Count:
				GL.DrawBuffers( dar.Count, dar.ToArray() )
			else:
				GL.DrawBuffer( DrawBufferMode.None )
		else:
			index = -1
			for k in range( at.Length-FBASE ):
				if mask & (1<<k) and A[k].Tex:
					index = k
					GL.ReadBuffer( ReadBufferMode.ColorAttachment0 + k )
					break
			GL.ReadBuffer( cast(ReadBufferMode,0) )	if index<0
		oldMask = mask
	
	private def updateUnits(target as FramebufferTarget) as void:
		for a in at:
			#todo: add RenderBuffer support
			t = a.Tex
			if t and a.dFormat.Dirty:	#change attachment texture format
				a.dFormat.clean()
				t.intFormat = a.Format
				t.samples = samples
				t.wid = Width
				t.het = Height
				if t.target != TextureTarget.TextureCubeMap:
					t.init()
				else:	t.initCube()
			if t and a.dLayer.Dirty:	#attach a layer of a 3D texture
				a.dLayer.clean()
				a.dLevel.clean()
				GL.FramebufferTextureLayer(	target,	a.slot, t.HardId, a.Level, a.Layer )
			elif a.dTex.Dirty or a.dLevel.Dirty:		#update texture attachment
				a.dTex.clean()
				a.dLevel.clean()
				if t and t.target in ( TextureTarget.TextureCubeMap, TextureTarget.Texture2DArray ):
					GL.FramebufferTexture(	target, a.slot, t.HardId, a.Level)
				elif t:
					GL.FramebufferTexture2D(target, a.slot, t.target, t.HardId, a.Level)
				else:
					GL.FramebufferTexture2D(target, a.slot, TextureTarget.Texture2D, 0, 0)
		Check(target)
	
	
	# -------- ACTIVATION ROUTINES ---------- #
	
	public def activate() as void:
		activate(true)
	public def activate(m as uint) as void:
		mask = m
		activate()
	public override def activate(draw as bool) as FramebufferTarget:
		tg = super(draw)
		updateMask(draw)
		updateUnits(tg)
		return tg
