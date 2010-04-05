namespace kri.rend.light

import System
import OpenTK.Graphics.OpenGL
import kri

	
#---------	LIGHT MAP FILL	--------#

public class Fill( rend.tech.General ):
	protected final buf		= frame.Buffer()
	protected final sa		= shade.Smart()
	protected final licon	as Context

	public def constructor(lc as Context):
		super('lit.bake')
		buf.mask = 0
		licon = lc
		# spot shader
		sa.add( '/light/bake_v', ('empty','/light/bake_exp_f')[lc.expo], 'tool', 'quat', 'fixed' )
		sa.link( Ant.Inst.slotAttributes, lc.dict, Ant.Inst.dict )

	private override def construct(mat as Material) as shade.Smart:
		return sa

	public override def process(con as rend.Context) as void:
		con.SetDepth(1f, true)
		Texture.Slot( kri.lib.Const.offUnit )
		for l in Scene.current.lights:
			continue if l.fov == 0f
			Ant.Inst.params.activate(l)
			buf.init(licon.size, licon.size)
			if not l.depth:
				l.depth = buf.A[-1].new( licon.bits, TextureTarget.Texture2D )
			else:	buf.A[-1].Tex = l.depth
			buf.activate()
			GL.Clear( ClearBufferMask.DepthBufferBit )
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
		name = ('simple','exponent2')[lc.expo]
		super('lit.apply', kri.load.Meta.LightSet,
			('/light/apply_v','/light/apply_f','/light/common_f',"/light/shadow/${name}_f") )
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
			Texture.Shadow(not licon.expo)
			Texture.Filter(licon.smooth, licon.mipmap)
			# determine subset of affected objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()


#-----------------------------------------------------------------------------------------#
#	VARIANCE SHADOW MAPS
#---

public class FillVar( rend.tech.General ):
	protected final buf		= frame.Buffer()
	protected final sa		= shade.Smart()
	protected final sb		= shade.Smart()
	protected final licon	as Context

	public def constructor(lc as Context):
		super('lit.var.bake')
		licon = lc
		# buffer init
		buf.mask = 1
		buf.init( lc.size, lc.size )
		buf.A[-1].new(0)
		# spot shader
		sa.add( '/light/bake_var_v', '/light/bake_var_f', 'tool', 'quat', 'fixed' )
		sa.link( Ant.Inst.slotAttributes, lc.dict, Ant.Inst.dict )

	private override def construct(mat as Material) as shade.Smart:
		return sa

	public override def process(con as rend.Context) as void:
		con.SetDepth(0f, true)
		Texture.Slot( kri.lib.Const.offUnit )
		for l in Scene.current.lights:
			continue if l.fov == 0f
			Ant.Inst.params.activate(l)
			if not l.depth:
				l.depth = buf.A[0].new( PixelInternalFormat.Rg16, TextureTarget.Texture2D )
			else:	buf.A[0].Tex = l.depth
			buf.activate()
			con.ClearColor( OpenTK.Graphics.Color4.White )
			con.ClearDepth( 1f )
			drawScene()
			if licon.mipmap:
				l.depth.bind()
				Texture.GenLevels()


public class ApplyVar( rend.tech.Meta ):
	private lit as Light	= null
	private final licon		as Context
	private final texLit	= shade.par.Texture(0,'light')

	public def constructor(lc as Context):
		super('lit.var.apply', kri.load.Meta.LightSet,
			('/light/apply_v','/light/apply_f','/light/shadow/variance_f','/light/common_f') )
		dict.attach( lc.dict )
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
			Texture.Shadow(false)
			Texture.Filter(licon.smooth, licon.mipmap)
			# determine subset of affected objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()
