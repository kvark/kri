namespace kri.rend.light

import OpenTK.Graphics.OpenGL

public enum LiType:
	SIMPLE
	EXPONENT
	VARIANCE

#---------	LIGHT CONTEXT	--------#

public class Context:
	public final size	as uint
	public final layers	as uint
	public bits	as uint	= 0
	public final pDark	= kri.shade.par.Value[of single]()
	public final pX		= kri.shade.par.Value[of OpenTK.Vector4]()
	public final pOff	= kri.shade.par.Value[of single]()
	public final pHemi	= kri.shade.par.Value[of single]()
	public final dict	= kri.shade.rep.Dict()
	public mipmap	as bool = false
	public smooth	as bool	= true
	public type 	= LiType.SIMPLE
	public final defShadow	= kri.Texture( TextureTarget.Texture2D )
	# init
	public def constructor(nlay as uint, qlog as uint):
		dict.add('k_dark',			pDark)
		dict.add('dark',			pX)
		dict.add('texel_offset',	pOff)
		dict.add('hemi',			pHemi)
		layers,size	= nlay,1<<qlog
		defShadow.bind()
		kri.Texture.Filter(false,false)
		kri.Texture.Init(1,1, PixelInternalFormat.DepthComponent, (-1,))
	# exponential
	public def setExpo(darkness as single, kernel as single) as void:
		type = LiType.EXPONENT
		bits = 32
		pDark.Value	= darkness
		pOff.Value	= kernel / size
		pX.Value = OpenTK.Vector4(5f, 5f, 4f, kernel / size)
	# variance
	public def setVariance() as void:
		type = LiType.VARIANCE
		bits = 0