namespace support.light

import kri.shade

public enum ShadowType:
	Simple
	Exponent
	Variance
public enum OmniType:
	None
	Dual
	Cube

#---------	LIGHT CONTEXT	--------#

public class Context:
	public final size	as uint	= 0
	public final layers	as uint	= 0
	public final texLit	= par.Texture('light')
	public final pDark	= par.Value[of single]('k_dark')
	public final pX		= par.Value[of OpenTK.Vector4]('dark')
	public final pOff	= par.Value[of single]('texel_offset')
	public final pHemi	= par.Value[of single]('hemi')
	public final dict	= par.Dict()
	public bits		as uint	= 0
	public mipmap	as bool = false
	public smooth	as bool	= true
	public shadowType 		= ShadowType.Simple
	public final defShadow	= kri.gen.Texture.depth
	public final sh_dummy	= Object.Load('/light/shadow/dummy_f')
	public final sh_common	= Object.Load('/light/common_f')

	# init
	public def constructor():
		dict.var(pDark,pOff,pHemi)
		dict.var(pX)
		dict.unit(texLit)
	public def constructor(nlay as uint, qlog as uint):
		self()
		layers,size	= nlay,1<<qlog

	# exponential
	public def setExpo(darkness as single, kernel as single) as void:
		shadowType = ShadowType.Exponent
		bits = 32
		pDark.Value	= darkness
		pOff.Value	= kernel / size
		pX.Value = OpenTK.Vector4(5f, 5f, 4f, kernel / size)
	# variance
	public def setVariance() as void:
		shadowType = ShadowType.Variance
		bits = 0

	# shadow shaders
	public def getFillShader() as Object:
		name = '/empty_f'
		name = '/light/bake_exp_f'	if shadowType == ShadowType.Exponent
		name = '/light/bake_var_f'	if shadowType == ShadowType.Variance
		return Object.Load(name)
	
	public def getApplyShader(ot as OmniType) as Object:
		path = '/light/shadow' + {
			OmniType.None:	'',
			OmniType.Cube:	'/cube',
			OmniType.Dual:	'/dual',
		}[ot]
		name = {
			ShadowType.Simple:		'simple',
			ShadowType.Exponent:	'exponent2',
			ShadowType.Variance:	'variance',
		}[shadowType]
		return Object.Load("${path}/${name}_f")
	
	public def getApplyShader() as Object:
		return getApplyShader( OmniType.None )