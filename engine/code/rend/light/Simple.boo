namespace kri.rend.light

import System
import OpenTK.Graphics.OpenGL
import kri

	
#---------	LIGHT MAP FILL	--------#

public class Fill( rend.tech.General ):
	public final buf		= frame.Buffer()
	protected final sa		= shade.Smart()
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
		baker = 'empty'
		baker = '/light/bake_exp_f'	if lc.type == LiType.EXPONENT
		baker = '/light/bake_var_f'	if lc.type == LiType.VARIANCE
		sa.add( '/light/bake_v', baker, 'tool', 'quat', 'fixed' )
		sa.link( Ant.Inst.slotAttributes, lc.dict, Ant.Inst.dict )

	private override def construct(mat as Material) as shade.Smart:
		return sa

	public override def process(con as rend.Context) as void:
		con.SetDepth(1f, true)
		Texture.Slot( lib.Const.offUnit )
		for l in Scene.current.lights:
			continue if l.fov == 0f
			Ant.Inst.params.activate(l)
			index = (-1,0)[licon.type == LiType.VARIANCE]
			if not l.depth:
				ask = Texture.AskFormat(Texture.Class.Depth, licon.bits)
				pif = (ask, PixelInternalFormat.Rg16)[index+1]
				l.depth = buf.A[index].new( pif, TextureTarget.Texture2D )
			else:	buf.A[index].Tex = l.depth
			buf.activate()
			con.ClearColor( OpenTK.Graphics.Color4.White )
			con.ClearDepth( 1f )
			drawScene()
			if licon.mipmap:
				l.depth.bind()
				Texture.GenLevels()


#---------	LIGHT MAP APPLY	--------#

public class Apply( rend.tech.Meta ):
	private lit as Light	= null
	private final licon		as Context
	private final texLit	= shade.par.Texture(0,'light')

	public def constructor(lc as Context):
		shadow = 'simple'
		shadow = 'exponent2'	if lc.type == LiType.EXPONENT
		shadow = 'variance'		if lc.type == LiType.VARIANCE
		super('lit.apply', null, kri.load.Meta.LightSet,
			('/light/apply_v','/light/apply_f','/light/common_f',"/light/shadow/${shadow}_f") )
		dict.attach(lc.dict)
		dict.unit(texLit)
		licon = lc
	# prepare
	protected override def getUpdate(mat as Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit	# need current light only
		return def() as int:
			texLit.Value = curLight.depth
			Ant.Inst.params.activate(curLight)
			return metaFun()
	# work
	public override def process(con as rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		for l in Scene.current.lights:
			continue if l.fov == 0f
			lit = l
			texLit.bindSlot( l.depth )
			Texture.Shadow( licon.type == LiType.SIMPLE )
			Texture.Filter(licon.smooth, licon.mipmap)
			# determine subset of affected objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()
