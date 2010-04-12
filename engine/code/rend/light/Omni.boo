namespace kri.rend.light.omni

import System
import OpenTK
import OpenTK.Graphics.OpenGL
import kri

#---------	LIGHT OMNI FILL	--------#

public class Fill( rend.tech.General ):
	protected final buf		= frame.Buffer()
	protected final sa		= shade.Smart()
	protected final context	as rend.light.Context
	protected final pDist	= shade.par.Value[of Vector4]()

	public def constructor(lc as rend.light.Context):
		super('lit.omni.bake')
		buf.mask = 0
		context = lc
		# omni shader
		sa.add( '/light/omni/bake_v', '/light/omni/bake_g', 'empty' )
		sa.add( *Ant.Inst.shaders.gentleSet )
		dict = shade.rep.Dict()
		dict.add( 'uni_dist', pDist )
		sa.link( Ant.Inst.slotAttributes, dict, lc.dict, Ant.Inst.dict )

	private override def construct(mat as Material) as shade.Smart:
		return sa
	private def setLight(l as Light) as void:
		Ant.Inst.params.litView.activate( l.node )
		k = 1f / (l.rangeOut - l.rangeIn)
		pDist.Value = Vector4(k, l.rangeIn+l.rangeOut, 0f, 0f)

	public override def process(con as rend.Context) as void:
		con.SetDepth(1f, true)	# offset for HW filtering
		for l in Scene.current.lights:
			continue	if l.fov != 0f
			setLight(l)
			if not l.depth:
				l.depth = Texture( TextureTarget.TextureCubeMap )
				l.depth.bind()
				Texture.InitCube( Texture.AskFormat(Texture.Class.Depth,0), context.size )
				Texture.Shadow(true)
			buf.init(context.size, context.size)
			buf.A[-1].Tex = l.depth
			buf.activate()
			GL.ClearDepth( 1f )
			GL.Clear( ClearBufferMask.DepthBufferBit )
			#drawScene(1)


#---------	LIGHT OMNI APPLY	--------#

public class Apply( rend.tech.Meta ):
	private lit as Light	= null
	private final smooth	as bool
	public def constructor(bSmooth as bool):
		super('lit.omni.apply', null, *kri.load.Meta.LightSet)
		shade(('/light/omni/apply_v','/light/omni/apply_f','/light/common_f'))
		smooth = bSmooth
	protected override def getUpdate(mat as Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit
		return def() as int:
			kri.Ant.Inst.params.activate(curLight)
			return metaFun()
	public override def process(con as rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		Texture.Slot( lib.Const.offUnit )
		for l in Scene.current.lights:
			continue	if l.fov != 0f
			lit = l
			if l.depth:
				l.depth.bind()
				Texture.Shadow(false)
				Texture.Filter(false,false);
			# determine subset of affected objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()
