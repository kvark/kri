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
	public final texLit	= kri.shade.par.Texture('light')
	public final pDark	= kri.shade.par.Value[of single]('k_dark')
	public final pX		= kri.shade.par.Value[of OpenTK.Vector4]('dark')
	public final pOff	= kri.shade.par.Value[of single]('texel_offset')
	public final pHemi	= kri.shade.par.Value[of single]('hemi')
	public final dict	= kri.shade.rep.Dict()
	public mipmap	as bool = false
	public smooth	as bool	= true
	public type 	= LiType.SIMPLE
	public final defShadow	= kri.kit.gen.Texture.depth
	# init
	public def constructor(nlay as uint, qlog as uint):
		dict.var(pDark,pOff,pHemi)
		dict.var(pX)
		dict.unit(texLit)
		layers,size	= nlay,1<<qlog
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
