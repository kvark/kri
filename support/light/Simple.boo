namespace support.light

import System
import OpenTK.Graphics.OpenGL

	
#---------	LIGHT MAP FILL	--------#

public class Fill( kri.rend.tech.General ):
	public final buf		= kri.frame.Buffer()
	protected final sa		= kri.shade.Smart()
	protected final licon	as Context

	public def constructor(lc as Context):
		super('lit.bake')
		licon = lc
		# buffer init
		buf.init(lc.size, lc.size)
		if lc.type == LiType.VARIANCE:
			buf.mask = 1
			buf.emitAuto(-1,0)
			buf.emit(1, PixelInternalFormat.Rg16 )
		else: buf.mask = 0
		# spot shader
		sa.add( '/light/bake_v', '/lib/tool_v', '/lib/quat_v', '/lib/fixed_v' )
		sa.add( lc.getFillShader() )
		sa.link( kri.Ant.Inst.slotAttributes, lc.dict, kri.Ant.Inst.dict )

	public override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa

	public override def process(con as kri.rend.Context) as void:
		con.SetDepth(1f, true)
		for l in kri.Scene.Current.lights:
			continue if l.fov == 0f
			kri.Ant.Inst.params.activate(l)
			index = (-1,0)[licon.type == LiType.VARIANCE]
			if not l.depth:
				ask = kri.frame.Buffer.AskFormat( kri.frame.Buffer.Class.Depth, licon.bits )
				pif = (ask, PixelInternalFormat.Rg16)[index+1]
				l.depth = buf.emit(index,pif)
				l.depth.pixFormat = PixelFormat.DepthComponent
			else:	buf.A[index].Tex = l.depth
			buf.activate()
			con.ClearColor( OpenTK.Graphics.Color4.White )	if not index
			con.ClearDepth( 1f )
			drawScene()
			# post-prepare texture
			kri.buf.Texture.Slot(8)
			l.depth.genLevels()	if licon.mipmap
			l.depth.filt( licon.smooth, licon.mipmap )
			l.depth.shadow( licon.type == LiType.SIMPLE )


#---------	LIGHT MAP APPLY	--------#

public class Apply( kri.rend.tech.Meta ):
	private lit as kri.Light	= null
	private final texLit	as kri.shade.par.Texture

	public def constructor(lc as Context):
		super('lit.apply', false, null, *kri.load.Meta.LightSet)
		shobs.Add( lc.getApplyShader() )
		shade(('/light/apply_v','/light/apply_f','/light/common_f'))
		dict.attach(lc.dict)
		texLit = lc.texLit
	# prepare
	protected override def getUpdater(mat as kri.Material) as Updater:
		metaFun = super(mat).fun
		curLight = lit	# need current light only
		return Updater() do() as int:
			texLit.Value = curLight.depth
			kri.Ant.Inst.params.activate(curLight)
			return metaFun()
	# work
	public override def process(con as kri.rend.Context) as void:
		butch.Clear()
		for l in kri.Scene.Current.lights:
			continue if l.fov == 0f
			lit = l
			texLit.Value = l.depth
			# determine subset of affected objects
			for e in kri.Scene.Current.entities:
				addObject(e)
		butch.Sort( kri.rend.tech.Batch.cMat )
		# draw
		con.activate(true, 0f, false)
		using blend = kri.Blender():
			blend.add()
			for b in butch:
				b.draw()
