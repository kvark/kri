namespace kri.rend.light.omni

import System
import OpenTK
import OpenTK.Graphics.OpenGL


#---------	LIGHT OMNI FILL	--------#

public class Fill( kri.rend.tech.General ):
	protected final buf		= kri.frame.Buffer(0, TextureTarget.TextureCubeMap )
	protected final sa		= kri.shade.Smart()
	protected final context	as kri.rend.light.Context
	protected final pDist	= kri.shade.par.Value[of Vector4]('uni_dist')

	public def constructor(lc as kri.rend.light.Context):
		super('lit.omni.bake')
		buf.mask = 0
		context = lc
		# omni shader
		sa.add( '/light/omni/bake_v', '/light/omni/bake_g', '/empty_f' )
		sa.add( *kri.Ant.Inst.libShaders )
		dict = kri.shade.rep.Dict()
		dict.var(pDist)
		sa.link( kri.Ant.Inst.slotAttributes, dict, lc.dict, kri.Ant.Inst.dict )

	public override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa
	private def setLight(l as kri.Light) as void:
		kri.Ant.Inst.params.litView.activate( l.node )
		k = 1f / (l.rangeOut - l.rangeIn)
		pDist.Value = Vector4(k, l.rangeIn+l.rangeOut, 0f, 0f)

	public override def process(con as kri.rend.Context) as void:
		con.SetDepth(1f, true)	# offset for HW filtering
		for l in kri.Scene.current.lights:
			continue	if l.fov != 0f
			setLight(l)
			buf.init( context.size, context.size )
			if not l.depth:
				l.depth = buf.emit(-1,0)
			else:	buf.A[-1].Tex = l.depth
			buf.activate()
			GL.ClearDepth( 1f )
			GL.Clear( ClearBufferMask.DepthBufferBit )
			drawScene()


#---------	LIGHT OMNI APPLY	--------#

public class Apply( kri.rend.tech.Meta ):
	private lit as kri.Light	= null
	private final smooth	as bool
	public def constructor(bSmooth as bool):
		super('lit.omni.apply', false, null, *kri.load.Meta.LightSet)
		shade(('/light/omni/apply_v','/light/omni/apply_f','/light/common_f'))
		smooth = bSmooth
	protected override def getUpdate(mat as kri.Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit
		return def() as int:
			kri.Ant.Inst.params.activate(curLight)
			return metaFun()
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		#Texture.Slot(8)
		for l in kri.Scene.current.lights:
			continue	if l.fov != 0f
			lit = l
			#if l.depth:
			#	l.depth.bind()
			#	Texture.Shadow(false)
			#	Texture.Filter(false,false);
			# determine subset of affected objects
			for e in kri.Scene.Current.entities:
				addObject(e)
		using blend = kri.Blender():
			blend.add()
			butch.Sort( kri.rend.tech.Batch.cMat )
			for b in butch:
				b.draw()
