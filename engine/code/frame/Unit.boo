namespace kri.frame

import OpenTK.Graphics.OpenGL

#--------- Simple dirty value holder	---------#
public struct DirtyHolder[of T]:
	[getter(Dirty)]
	private dirty	as bool
	private val		as T
	public def constructor(t as T):
		Value = t
	public Value	as T:
		get: return val
		set: dirty,val = true,value
	public def clean() as void:
		dirty = false


#---------	Single frame representor inside the FBO	---------#

public class Unit:
	public final slot	as FramebufferAttachment				# fbo slot
	internal dTex		= DirtyHolder[of kri.Texture](null)		# texture
	internal dLayer		= DirtyHolder[of byte](0)				# layer id
	internal dFormat	= DirtyHolder[of PixelInternalFormat]( kri.Fm.bad )	# pixel format
	portal Tex	as kri.Texture	= dTex.Value
	
	internal def constructor(s as FramebufferAttachment):
		slot = s
	public Layer as int:
		get: return dLayer.Value
	public Format as PixelInternalFormat:
		get: return dFormat.Value
	
	# custom internal format
	public def make(pif as PixelInternalFormat, targ as TextureTarget) as kri.Texture:
		Tex = kri.Texture(targ)
		dFormat.Value = pif
		return Tex
	# format defined by class & bits
	public def make(cl as kri.Texture.Class, bits as byte, targ as TextureTarget) as kri.Texture:
		if cl == kri.Texture.Class.Stencil:	assert slot == FramebufferAttachment.DepthStencilAttachment
		if cl == kri.Texture.Class.Depth:	assert slot == FramebufferAttachment.DepthAttachment
		return make( kri.Texture.AskFormat(cl,bits), targ )
	# class defined by slot
	public def make(bits as byte, targ as TextureTarget) as kri.Texture:
		cl = kri.Texture.Class.Color
		if slot == FramebufferAttachment.DepthStencilAttachment:
			cl = kri.Texture.Class.Stencil
		if slot == FramebufferAttachment.DepthAttachment:
			cl = kri.Texture.Class.Depth
		return make( cl, bits, targ )
	# set texture layer
	public def layer(t as kri.Texture, z as int) as void:
		Tex = t	if t
		dLayer.Value = z
