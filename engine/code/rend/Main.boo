namespace kri.rend

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------	BASIC RENDER	--------#

public class Basic:
	public			active	as bool = true
	public final	bInput	as bool
	public def constructor(inp as bool):
		bInput = inp
	public virtual def setup(far as kri.frame.Array) as bool:
		return true
	public virtual def process(con as Context) as void:
		pass


#---------	RENDER CHAIN MANAGER	--------#

public class Chain(Basic):
	public final	renders	= List[of Basic]()		# *Render
	public final	toScreen	as bool
	
	public def constructor(inp as bool, out as bool):
		super(inp)
		toScreen = out
	public def constructor():
		super(false)
		toScreen = true
	
	public override def setup(far as kri.frame.Array) as bool:
		return renders.TrueForAll() do(r as Basic):
			return r.setup(far)
		
	public override def process(con as Context) as void:
		rout = renders.FindLast() do(r as Basic):	# first render to out
			return r.bInput
		con.Screen = not rout
		for r in renders:
			continue	if not r.active
			if r is rout:
				rout = null
				con.Screen = toScreen
			con.apply(r)


#---------	GENERAL FILTER	--------#

public class Filter(Basic):
	protected final prog as kri.shade.Program
	public def constructor(program as kri.shade.Program):
		super(true)
		prog = program
	public override def process(con as Context) as void:
		con.activate()
		prog.use()
		kri.Ant.inst.emitQuad()

public class FilterCopy(Filter):
	public def constructor():
		sa = kri.shade.Smart()
		sa.add('copy_v','/copy_screen_f')
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		super(sa)


#---------	RENDER PARTICLES		--------#

public class Particles(Basic):
	public def constructor():
		super(false)
	public override def process(con as Context) as void:
		con.activate(true, 0f, false)
		using blend = kri.Blender(), kri.Section( EnableCap.ClipPlane0 ):
			blend.add()
			#TODO: per-manager sorting
			for pe in kri.Scene.Current.particles:
				continue if not pe.obj
				kri.Ant.Inst.params.modelView.activate( pe.obj.node )
				pe.man.draw(pe)
