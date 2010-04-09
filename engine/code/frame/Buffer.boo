namespace kri.frame

import System
import OpenTK.Graphics.OpenGL

#--------- Simple dirty value holder	---------#
internal struct DirtyHolder[of T]:
	[getter(Dirty)]
	private dirty	as bool
	private val		as T
	internal Value	as T:
		set: dirty,val = true,value
		get: return val
	internal def clean():
		dirty = false


#---------	Single frame representor inside the FBO	---------#

public class Unit:
	internal tex		as kri.Texture = null					# texture
	internal dLayer		as DirtyHolder[of int]					# layer id
	internal dFormat	as DirtyHolder[of PixelInternalFormat]	# pixel format
	internal dirty		as bool = false							# tex changed
	[getter(Slot)]
	private final slot	as FramebufferAttachment				# fbo slot
	
	internal def constructor(s as FramebufferAttachment):
		slot = s
	public Tex as kri.Texture:
		get: return tex
		set: tex,dirty = value,true
	public Layer as int:
		get: return dLayer.Value
	public Format as PixelInternalFormat:
		get: return dFormat.Value
	
	# custom internal format
	public def new(pif as PixelInternalFormat, targ as TextureTarget) as kri.Texture:
		Tex = kri.Texture(targ)
		dFormat.Value = pif
		return tex
	# format defined by class & bits
	public def new(cl as kri.Texture.Class, bits as uint, targ as TextureTarget) as kri.Texture:
		if cl == kri.Texture.Class.Stencil:	assert slot == FramebufferAttachment.DepthStencilAttachment
		if cl == kri.Texture.Class.Depth:	assert slot == FramebufferAttachment.DepthAttachment
		return new( kri.Texture.AskFormat(cl,bits), targ )
	# class defined by slot
	public def new(bits as uint, targ as TextureTarget) as kri.Texture:
		cl = kri.Texture.Class.Color
		if slot == FramebufferAttachment.DepthStencilAttachment:
			cl = kri.Texture.Class.Stencil
		if slot == FramebufferAttachment.DepthAttachment:
			cl = kri.Texture.Class.Depth
		return new( cl, bits, targ )
	# target is rectangle
	public def new(bits as uint) as kri.Texture:
		return new(bits, TextureTarget.TextureRectangle)
	# set texture layer
	public def layer(t as kri.Texture, z as int) as void:
		tex = t	if t
		dLayer.Value = z


#---------	Basic Framebuffer container	---------#

public class Array:
	protected dirtyPort = true	# need to update Viewport
	[getter(Width)]
	private wid as uint = 0
	[getter(Height)]
	private het as uint = 0

	public def init(x as uint, y as uint) as void:
		dirtyPort = true
		wid,het = x,y
	public static def Clear(depth as bool) as void:
		mask = ClearBufferMask.ColorBufferBit
		if depth:
			mask |= ClearBufferMask.DepthBufferBit
		GL.Clear(mask)


#---------	FB with offset, clear & activate	---------#

public class Screen(Array):
	private ofx as int = 0
	private ofy as int = 0
	protected final id as int
	public def constructor():
		id = 0
	protected def constructor(newid as int):
		id = newid
	public def offset(x as int, y as int) as void:
		dirtyPort = true
		ofx,ofy = x,y
	public virtual def activate() as void:
		assert Width*Height
		GL.BindFramebuffer(FramebufferTarget.Framebuffer, id)
		#return if not dirtyPort
		GL.Viewport(ofx,ofy, ofx+Width,ofy+Height)
		dirtyPort = false


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
		tmp = id
		kri.safeKill({ GL.DeleteFramebuffers(1,tmp) })
	
	public static def Check() as bool:
		status = GL.CheckFramebufferStatus(FramebufferTarget.Framebuffer)
		return status == FramebufferErrorCode.FramebufferComplete
		
	public def dropMask() as void:
		oldMask = 100
	
	public def resizeFrames() as void:
		for a in at:
			continue	if not a.Tex
			a.Tex.bind()
			kri.Texture.Init(Width, Height, a.Format)
			a.dFormat.clean()
	
	public def activate(m as uint) as void:
		mask = m
		activate()
	public override def activate() as void:
		super()
		if mask != oldMask:
			# select buffer to draw & read
			arr = List[of DrawBuffersEnum]()
			for k in range(at.Length-FBASE):
				if mask & (1<<k) and A[k].Tex:
					arr.Add( DrawBuffersEnum.ColorAttachment0 + k )
			if arr.Count:
				GL.DrawBuffers(arr.Count, arr.ToArray())
			else:
				GL.DrawBuffer( DrawBufferMode.None )
				GL.ReadBuffer( cast(ReadBufferMode,0) )
			oldMask = mask
		for a in at:
			t = a.Tex
			if t and a.dFormat.Dirty:	#change attachment texture format
				a.dFormat.clean()
				t.bind()
				kri.Texture.Init(Width, Height, a.Format)
			if t and a.dLayer.Dirty:	#attach a layer of a 3D texture
				a.dLayer.clean()
				GL.FramebufferTextureLayer(FramebufferTarget.Framebuffer,
					a.Slot, t.id, 0, a.Layer)
			elif a.dirty:		#update texture attachment
				#TODO: use core
				if t and t.type in (TextureTarget.TextureCubeMap, TextureTarget.Texture2DArray):
					GL.Arb.FramebufferTexture( FramebufferTarget.Framebuffer, a.Slot, t.id, 0)
				elif t:
					GL.FramebufferTexture2D( FramebufferTarget.Framebuffer,	a.Slot, t.type, t.id, 0)
				else:
					GL.FramebufferTexture2D( FramebufferTarget.Framebuffer,	a.Slot,
						TextureTarget.Texture2D, 0, 0)
