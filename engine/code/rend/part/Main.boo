namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


public class Basic( kri.rend.Basic ):
	public ats	as (int)	= null
	public def constructor():
		super(false)
	public override def setup() as bool:
		ats = (0,1)	# get actual attribs from the program
	public override def process(con as kri.rend.Context) as void:
		for pe in kri.Scene.Current.particles:
			pass


#---------	RENDER PARTICLES		--------#

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
			/*
			lis = List[of kri.part.Emitter]( kri.Scene.Current.particles )
			while lis.Count:
				man = lis[0].owner	
				pred = {p as kri.part.Emitter| return p.man == man }
				for pe in lis.FindAll(pred):
					draw(pe)
				lis.RemoveAll(pred)
			*/