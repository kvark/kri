namespace kri.rend.light

import System
import OpenTK.Graphics.OpenGL

	
#---------	LIGHT MAP FILL	--------#

public class Fill( kri.rend.tech.General ):
	public final buf		= kri.frame.Buffer()
	public final sh_bake	as kri.shade.Object
	protected final sa		= kri.shade.Smart()
	protected final licon	as Context

	public def constructor(lc as Context):
		super('lit.bake')
		licon = lc
		# buffer init
		buf.init(lc.size, lc.size)
		if lc.type == LiType.VARIANCE:
			buf.mask = 1
			buf.A[-1].new(0)
			buf.A[1].new( PixelInternalFormat.Rg16, TextureTarget.Texture2D )
		else: buf.mask = 0
		# spot shader
		baker = '/empty_f'
		baker = '/light/bake_exp_f'	if lc.type == LiType.EXPONENT
		baker = '/light/bake_var_f'	if lc.type == LiType.VARIANCE
		sh_bake = kri.shade.Object(baker)
		sa.add( '/light/bake_v', 'tool', 'quat', 'fixed' )
		sa.add( sh_bake )
		sa.link( kri.Ant.Inst.slotAttributes, lc.dict, kri.Ant.Inst.dict )

	public override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa

	public override def process(con as kri.rend.Context) as void:
		con.SetDepth(1f, true)
		kri.Texture.Slot(8)
		for l in kri.Scene.current.lights:
			continue if l.fov == 0f
			kri.Ant.Inst.params.activate(l)
			index = (-1,0)[licon.type == LiType.VARIANCE]
			if not l.depth:
				ask = kri.Texture.AskFormat( kri.Texture.Class.Depth, licon.bits )
				pif = (ask, PixelInternalFormat.Rg16)[index+1]
				l.depth = buf.A[index].new( pif, TextureTarget.Texture2D )
			else:	buf.A[index].Tex = l.depth
			buf.activate()
			con.ClearColor( OpenTK.Graphics.Color4.White )	if not index
			con.ClearDepth( 1f )
			drawScene()
			if licon.mipmap:
				l.depth.bind()
				kri.Texture.GenLevels()


#---------	LIGHT MAP APPLY	--------#

public class Apply( kri.rend.tech.Meta ):
	private lit as kri.Light	= null
	private final licon		as Context
	private final texLit	= kri.shade.par.Value[of kri.Texture]('light')

	public def constructor(lc as Context):
		shadow = 'simple'
		shadow = 'exponent2'	if lc.type == LiType.EXPONENT
		shadow = 'variance'		if lc.type == LiType.VARIANCE
		super('lit.apply', null, *kri.load.Meta.LightSet)
		shade(('/light/apply_v','/light/apply_f','/light/common_f',"/light/shadow/${shadow}_f"))
		dict.attach(lc.dict)
		dict.unit(texLit.Name,texLit)
		licon = lc
	# prepare
	protected override def getUpdate(mat as kri.Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit	# need current light only
		return def() as int:
			texLit.Value = curLight.depth
			kri.Ant.Inst.params.activate(curLight)
			return metaFun()
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		for l in kri.Scene.current.lights:
			continue if l.fov == 0f
			lit = l
			texLit.Value = l.depth
			l.depth.bind()
			kri.Texture.Shadow( licon.type == LiType.SIMPLE )
			kri.Texture.Filter( licon.smooth, licon.mipmap )
			# determine subset of affected objects
			for e in kri.Scene.Current.entities:
				addObject(e)
		using blend = kri.Blender():
			blend.add()
			butch.Sort( kri.rend.tech.Batch.cMat )
			for b in butch:
				b.draw()
