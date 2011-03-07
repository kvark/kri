namespace kri.frame

import OpenTK.Graphics.OpenGL

#--------- Simple dirty value holder	---------#
public class DirtyHolder[of T]:
	[getter(Dirty)]
	private dirty	as bool
	private val		as T
	public def constructor(t as T):
		val = t
		dirty = false
	public Value	as T:
		get: return val
		set: dirty,val = true,value
	public def clean() as void:
		dirty = false


#---------	Single frame representor inside the FBO	---------#

public class Unit:
	public final slot	as FramebufferAttachment				# fbo slot
	internal dTex		= DirtyHolder[of kri.buf.Texture](null)		# texture
	internal dLayer		= DirtyHolder[of byte](0)				# layer id
	internal dLevel		= DirtyHolder[of byte](0)				# LOD level
	internal dFormat	= DirtyHolder[of PixelInternalFormat]( kri.Fm.bad )	# pixel format
	
	portal Tex		as kri.buf.Texture	= dTex.Value
	portal Layer	as int			= dLayer.Value
	portal Level	as int			= dLevel.Value
	portal Format	as PixelInternalFormat	= dFormat.Value
	
	internal def constructor(s as FramebufferAttachment):
		slot = s
