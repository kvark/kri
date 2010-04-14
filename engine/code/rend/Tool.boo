namespace kri.rend

import System
import OpenTK.Graphics

#---------	COLOR CLEAR	--------#

public class Clear( Basic ):
	public backColor	= Color4.Black
	public def constructor():
		super(false)
	public override def process(con as Context) as void:
		con.activate()
		con.ClearColor( backColor )


#---------	EARLY Z FILL	--------#

public class EarlyZ( tech.General ):
	private sa	= kri.shade.Smart()
	public def constructor():
		super('zcull')
		# make shader
		sa.add( '/zcull_v', 'empty', 'tool', 'quat', 'fixed' )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	private override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa
	public override def process(con as Context) as void:
		con.activate(false, 1f, true)
		con.ClearDepth(1f)
		drawScene()


#---------	INITIAL FILL EMISSION	--------#

public class Emission( tech.Meta ):
	public final pBase	= kri.shade.par.Value[of Color4]()
	public fillDepth	= false
	public backColor	= Color4.Black
	
	public def constructor():
		super('mat.emission', null, 'emissive')
		shade('/mat_base2')
		dict.add('base_color', pBase)
		pBase.Value = Color4.Black
	public override def process(con as Context) as void:
		if fillDepth:
			con.activate(true, 1f, true)
			con.ClearDepth(1f)
		else: con.activate()
		con.ClearColor( backColor )
		drawScene()


#---------	GAUSS FILTER	--------#

public class Gauss(Basic):
	protected final sa		= kri.shade.Smart()
	protected final sb		= kri.shade.Smart()
	protected final texIn	= kri.shade.par.Texture(0, 'input')
	public	buf		as kri.frame.Buffer	= null

	public def constructor():
		super(false)
		dict = kri.shade.rep.Dict()
		dict.unit(texIn)
		sa.add('copy_v','/filter/gauss_hor_f')
		sa.link( kri.Ant.Inst.slotAttributes, dict )
		sb.add('copy_v','/filter/gauss_ver_f')
		sb.link( kri.Ant.Inst.slotAttributes, dict )

	public override def process(con as Context) as void:
		return	if not buf
		assert buf.A[0].Tex and buf.A[1].Tex
		texIn.bindSlot( buf.A[0].Tex )
		kri.Texture.Filter(false,false)
		kri.Texture.Wrap( OpenGL.TextureWrapMode.Clamp, 2 )
		buf.activate(2)
		sa.use()
		kri.Ant.inst.emitQuad()
		texIn.bindSlot( buf.A[1].Tex )
		kri.Texture.Filter(false,false)
		kri.Texture.Wrap( OpenGL.TextureWrapMode.Clamp, 2 )
		buf.activate(1)
		sb.use()
		kri.Ant.inst.emitQuad()



#---------	RENDER SSAO	--------#


#---------	RENDER EVERYTHING AT ONCE	--------#

public class All( tech.General ):
	public def constructor():
		super('all')
	private override def construct(mat as kri.Material) as kri.shade.Smart:
		sa = kri.shade.Smart()
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		return sa
	public override def process(con as Context) as void:
		con.activate(true, 0f, true)
		con.ClearDepth(1f)
		con.ClearColor()
		drawScene()


#---------	RENDER PARTICLES		--------#

public class Particles(Basic):
	public final dTest	as bool
	public final bAdd	as bool
	public def constructor(depth as bool, add as bool):
		super(false)
		dTest,bAdd = depth,add
	public def draw(pe as kri.part.Emitter) as void:
		# assemble the shader from material's meta data
		pe.draw()
	public override def process(con as Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		using blend = kri.Blender(),\
		kri.Section( OpenGL.EnableCap.ClipPlane0 ),\
		kri.Section( OpenGL.EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			lis = List[of kri.part.Emitter]( kri.Scene.Current.particles )
			while lis.Count:
				man = lis[0].man
				pred = {p as kri.part.Emitter| return p.man == man }
				for pe in lis.FindAll(pred):
					draw(pe)
				lis.RemoveAll(pred)
