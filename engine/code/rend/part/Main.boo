namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PARTICLES		--------#

public class Basic( kri.rend.Basic ):
	public final dTest	as bool
	public final bAdd	as bool
	protected final sa		= kri.shade.Smart()
	private ats	as (int)	= null
	
	public def constructor(depth as bool, add as bool):
		super(false)
		dTest,bAdd = depth,add
	public override def setup(far as kri.frame.Array) as bool:
		ats = array( sa.gatherAttribs(kri.Ant.Inst.slotParticles) )
		return true
	public override def process(con as kri.rend.Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		sa.use()
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			for pe in kri.Scene.Current.particles:
				pat = pe.listAttribs()
				continue if not Array.TrueForAll(ats, {a| return a in pat })
				pe.va.bind()
				return	if not pe.prepare()
				GL.DrawArrays( BeginMode.Points, 0, pe.owner.total )


#---------	TECHNIQUE	--------#

#public class Tech(Basic):
#	pass

#---------	SIMPLE		--------#

public class Simple( kri.rend.Basic ):
	public final dTest	as bool
	public final bAdd	as bool
	public final sa		= kri.shade.Smart()
	public def constructor(depth as bool, add as bool):
		super(false)
		dTest,bAdd = depth,add
		assert not 'ready'
		#sa.add( pcon.sh_draw )
		sa.add( './text/draw_simple_v', './text/draw_simple_f', 'quat','tool')
		sa.link( kri.Ant.Inst.slotParticles, kri.Ant.Inst.dict )	
	public override def process(con as kri.rend.Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			assert not 'ready'
			sa.use()
