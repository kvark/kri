namespace kri.rend

import System


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
	public final pBase	= kri.shade.par.Value[of OpenTK.Graphics.Color4]()
	public backColor	= OpenTK.Graphics.Color4(0,0,0,0)
	public fillDepth	= false
	
	public def constructor():
		super('mat.emission',
			(kri.Ant.Inst.units.texture,),
			(kri.Ant.Inst.slotMetas.find('emissive'),),
			(kri.shade.Object('/mat_base_f'), kri.shade.Object('/mat_base_v'))
			)
		dict.add('base_color', pBase)
		pBase.Value = backColor
	public override def process(con as Context) as void:
		if fillDepth:
			con.activate(true, 1f, true)
			con.ClearDepth(1f)
		else: con.activate()
		con.ClearColor( backColor )
		drawScene()



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
