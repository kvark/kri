namespace kri.rend

import System
import OpenTK.Graphics

#---------	COLOR CLEAR	--------#

public class Clear( Basic ):
	public backColor	= Color4.Black
	public override def process(con as link.Basic) as void:
		con.activate(false)
		con.ClearColor( backColor )


#---------	EARLY Z FILL	--------#

public class EarlyZ( tech.General ):
	public final sa	= kri.shade.Smart()
	public def constructor():
		super('zcull')
		# make shader
		sa.add( '/zcull_v', '/empty_f', '/lib/tool_v', '/lib/quat_v', '/lib/fixed_v' )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	public override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa
	public override def process(con as link.Basic) as void:
		con.activate( con.Target.None, 1f, true )
		con.ClearDepth(1f)
		drawScene()


#---------	INITIAL FILL EMISSION	--------#

public class Emission( tech.Meta ):
	public final pBase	= kri.shade.par.Value[of Color4]('base_color')
	public fillDepth	= false
	public backColor	= Color4.Black
	
	public def constructor():
		super('mat.emission', false, null, 'emissive')
		shade('/mat_base')
		dict.var(pBase)
		pBase.Value = Color4.Black
	public override def process(con as link.Basic) as void:
		if fillDepth:
			con.activate( con.Target.Same, 1f, true )
			con.ClearDepth(1f)
		else: con.activate( con.Target.Same, 0f, false )
		con.ClearColor( backColor )
		drawScene()


#---------	ADD COLOR	--------#

public class Color( tech.General ):
	private final sa	= kri.shade.Smart()
	private final add	as bool
	public def constructor(doAdd as bool):
		super('color')
		add = doAdd
		sa.add( '/color_v','/color_f', '/lib/quat_v','/lib/tool_v','/lib/fixed_v' )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	public override def construct(mat as kri.Material) as kri.shade.Smart:
		return sa
	public override def process(con as link.Basic) as void:
		con.activate( con.Target.Same, 0f, false )
		if add:
			using blend = kri.Blender():
				blend.add()
				drawScene()
		else:
			con.ClearColor()
			drawScene()


#---------	RENDER SSAO	--------#


#---------	RENDER EVERYTHING AT ONCE	--------#

public class All( tech.General ):
	public def constructor():
		super('all')
	public override def construct(mat as kri.Material) as kri.shade.Smart:
		sa = kri.shade.Smart()
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		return sa
	public override def process(con as link.Basic) as void:
		con.activate( con.Target.Same, 0f, true )
		con.ClearDepth(1f)
		con.ClearColor()
		drawScene()
