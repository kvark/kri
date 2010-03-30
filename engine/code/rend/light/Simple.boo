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
		Texture.Slot( Ant.Inst.units.light )
		for l in Scene.current.lights:
			continue if l.fov == 0f
			Ant.Inst.params.lightProj.activate(l)
			Ant.Inst.params.lightView.activate(l.node)
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
	public def constructor(lc as Context):
		ms = Array.ConvertAll(('diffuse','specular','parallax')) do(name as string):
			return Ant.Inst.slotMetas.find(name)
		name = ('simple','exponent2')[lc.expo]
		super('lit.apply',
			(Ant.Inst.units.texture, Ant.Inst.units.bump), ms,
			(shade.Object('/light/apply_v'), shade.Object('/light/apply_f'),
				shade.Object("/light/shadow/${name}_f") )
			)
		dict.attach(lc.dict)
		licon = lc
	# prepare
	protected override def getUpdate(mat as Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit	# need current light only
		return def() as int:
			curLight.apply()
			return metaFun()
	# work
	public override def process(con as rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		Texture.Slot( Ant.Inst.units.light )
		for l in Scene.current.lights:
			continue if l.fov == 0f
			lit = l
			l.depth.bind()
			Texture.Shadow(not licon.expo)
			Texture.Filter(licon.smooth, licon.mipmap)
			# determine subset of affect  ed objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()

#---------	LIGHT MAP APPLY: META-2	--------#

public class ApplyM2( rend.tech.Meta ):
	private lit as Light	= null
	private final licon		as Context
	private final metaLit	= meta.AdUnit( Name:'light' )

	public def constructor(lc as Context):
		name = ('simple','exponent2')[lc.expo]
		super('lit.apply', ('bump','diffuse','specular','glossiness'),
			array(shade.Object('/light/'+str) for str in ('apply2_v','apply2_f',"shadow/${name}_f"))
			)
		dict.attach(lc.dict)
		dict.unit(metaLit, 8)
		licon = lc
	# prepare
	protected override def getUpdate(mat as Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit	# need current light only
		return def() as int:
			metaLit.Value = curLight.depth
			curLight.apply()
			return metaFun()
	# work
	public override def process(con as rend.Context) as void:
		con.activate(true, 0f, false)
		butch.Clear()
		Texture.Slot(8)
		for l in Scene.current.lights:
			continue if l.fov == 0f
			lit = l
			l.depth.bind()
			Texture.Shadow(not licon.expo)
			Texture.Filter(licon.smooth, licon.mipmap)
			# determine subset of affect  ed objects
			for e in Scene.Current.entities:
				addObject(e)
		using blend = Blender():
			blend.add()
			butch.Sort( Batch.cMat )
			for b in butch:
				b.draw()
