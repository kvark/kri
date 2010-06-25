namespace kri.frame

import OpenTK.Graphics.OpenGL

#---------	FB lazy attachment management	---------#

public class Buffer(Screen):
	public mask		as uint = 1			# desired draw mask
	private oldMask	as uint = 0		# active mask
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
	
	public def constructor():
		tmp = 0
		GL.GenFramebuffers(1,tmp)
		super(tmp)
		dropMask()
	def destructor():
		tmp = Extract
		kri.Help.safeKill({ GL.DeleteFramebuffers(1,tmp) })
	
	public static def Check() as bool:
		status = GL.CheckFramebufferStatus( FramebufferTarget.Framebuffer )
		return status == FramebufferErrorCode.FramebufferComplete
		
	public def dropMask() as void:
		oldMask = 100
	
	public def resizeFrames() as void:
		for a in at:
			continue	if not a.Tex
			a.Tex.bind()
			kri.Texture.Init( Width, Height, a.Format )
			a.dFormat.clean()
	
	public def activate(m as uint) as void:
		mask = m
		activate()
	public override def activate() as void:
		super()
		if mask != oldMask:
			# select buffer to draw & read
			arr = List[of DrawBuffersEnum]()
			for k in range( at.Length-FBASE ):
				if mask & (1<<k) and A[k].Tex:
					arr.Add( DrawBuffersEnum.ColorAttachment0 + k )
			if arr.Count:
				GL.DrawBuffers( arr.Count, arr.ToArray() )
			else:
				GL.DrawBuffer( DrawBufferMode.None )
				GL.ReadBuffer( cast(ReadBufferMode,0) )
			oldMask = mask
		for a in at:
			#todo: add RenderBuffer support
			t = a.Tex
			if t and a.dFormat.Dirty:	#change attachment texture format
				a.dFormat.clean()
				t.bind()
				kri.Texture.Init(Width, Height, a.Format)
			if t and a.dLayer.Dirty:	#attach a layer of a 3D texture
				a.dLayer.clean()
				GL.FramebufferTextureLayer( FramebufferTarget.Framebuffer,
					a.slot, t.id, 0, a.Layer )
			elif a.dirty:		#update texture attachment
				if t and t.type in ( TextureTarget.TextureCubeMap, TextureTarget.Texture2DArray ):
					GL.FramebufferTexture( FramebufferTarget.Framebuffer, a.slot, t.id, 0)
				elif t:
					GL.FramebufferTexture2D( FramebufferTarget.Framebuffer,	a.slot, t.type, t.id, 0)
				else:
					GL.FramebufferTexture2D( FramebufferTarget.Framebuffer,	a.slot,
						TextureTarget.Texture2D, 0, 0)
