namespace kri.frame

import OpenTK.Graphics.OpenGL

#---------	FB lazy attachment management	---------#

public class Buffer(Screen):
	public mask		as uint = 1		# desired draw mask
	private oldMask	as uint = 0		# active mask
	private static final badMask	as uint = 100	# bad mask
	[Getter(Samples)]
	protected samples				as byte			# samples count
	
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
	
	public def constructor(nsam as byte):
		tmp = 0
		GL.GenFramebuffers(1,tmp)
		super(tmp)
		dropMask()
		samples = nsam
			
	def destructor():
		tmp = Extract
		kri.Help.safeKill({ GL.DeleteFramebuffers(1,tmp) })
	
	public static def Check(target as FramebufferTarget) as void:
		status = GL.CheckFramebufferStatus( target )
		assert status == FramebufferErrorCode.FramebufferComplete
	
	public def blit(what as ClearBufferMask) as void:
		GL.BlitFramebuffer(0,0,Width,Height,0,0,Width,Height,
			what, BlitFramebufferFilter.Nearest )
		
	public def dropMask() as void:
		oldMask = badMask
	
	public def resizeFrames() as void:
		for a in at:
			continue	if not a.Tex
			a.Tex.bind()
			kri.Texture.Init( a.Format, Width, Height, samples )
	public def resizeFrames(nsam as byte) as void:
		samples = nsam
		resizeFrames()
	
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
				kri.Texture.InitMulti( a.Format, samples,false, Width,Height,0 )
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
	
	public def activate() as void:
		activate(true)
	public def activate(m as uint) as void:
		mask = m
		activate()
	public override def activate(draw as bool) as FramebufferTarget:
		target = super(draw)
		updateMask(draw)
		updateUnits(target)
		return target
