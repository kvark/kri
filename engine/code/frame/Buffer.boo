namespace kri.frame

import OpenTK.Graphics.OpenGL

#---------	FB lazy attachment management	---------#

public class Buffer(Screen):
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
		self(0, TextureTarget.Texture1D )
			
	def destructor():
		tmp = Extract
		kri.Help.safeKill({ GL.DeleteFramebuffers(1,tmp) })
	
	public static def Check(target as FramebufferTarget) as void:
		status = GL.CheckFramebufferStatus( target )
		assert status == FramebufferErrorCode.FramebufferComplete
	
	
	# -------- CREATION ROUTINES ---------- #
	
	public def emit(id as int, pif as PixelInternalFormat) as kri.Texture:
		t = A[id].Tex = kri.Texture(texTarget)
		A[id].dFormat.Value = pif
		return t
	
	public def emit(id as int, cl as kri.Texture.Class, bits as byte) as kri.Texture:
		return emit( id, kri.Texture.AskFormat(cl,bits) )
	
	public def emitAuto(id as int, bits as byte) as kri.Texture:
		cl = kri.Texture.Class.Color
		if id==-2:	cl = kri.Texture.Class.Stencil
		if id==-1:	cl = kri.Texture.Class.Depth
		return emit( id, cl, bits )
	
	public def emitArray(num as int) as kri.Texture:
		tex = kri.Texture( TextureTarget.Texture2DArray )
		for i in range(num):
			A[i].Tex = tex
			A[i].Layer = i
		mask = (1<<num) - 1
		return tex
	

	# -------- AUXILARY ROUTINES ---------- #
	
	public def blit(what as ClearBufferMask) as void:
		GL.BlitFramebuffer(0,0,Width,Height,0,0,Width,Height,
			what, BlitFramebufferFilter.Nearest )
		
	public def dropMask() as void:
		oldMask = badMask
	
	public def resizeFrames() as void:
		for a in at:
			continue	if not a.Tex
			a.Tex.bind()
			kri.Texture.InitMulti( a.Format, samples,fixedSampleLoc, Width,Height,0 )
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
				t.bind()
				if t.target != TextureTarget.TextureCubeMap:
					kri.Texture.InitMulti( a.Format, samples,fixedSampleLoc, Width,Height,0 )
				else:	kri.Texture.InitCube( a.Format, Width )
			if t and a.dLayer.Dirty:	#attach a layer of a 3D texture
				a.dLayer.clean()
				GL.FramebufferTextureLayer(	target,	a.slot, t.id, 0, a.Layer )
			elif a.dTex.Dirty:		#update texture attachment
				a.dTex.clean()
				if t and t.target in ( TextureTarget.TextureCubeMap, TextureTarget.Texture2DArray ):
					GL.FramebufferTexture(	target, a.slot, t.id, 0)
				elif t:
					GL.FramebufferTexture2D(target, a.slot, t.target, t.id, 0)
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
