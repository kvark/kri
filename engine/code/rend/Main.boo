namespace kri.rend

import System.Collections.Generic


#---------	BASIC RENDER	--------#

public class Basic:
	public			active	as bool = true
	public final	bInput	as bool
	public def constructor(inp as bool):
		bInput = inp
	public def constructor():
		bInput = false
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
		toScreen = true
	
	public override def setup(far as kri.frame.Array) as bool:
		return renders.TrueForAll({r| r.setup(far) })
		
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
	protected final sa		= kri.shade.Smart()
	protected final texIn	= kri.shade.par.Value[of kri.Texture]('input')
	protected final dict	= kri.shade.rep.Dict()
	protected linear		= false
	public def constructor():
		super(true)
		dict.unit(texIn)
	public override def process(con as Context) as void:
		texIn.Value = con.Input
		con.Input.bind()
		kri.Texture.Filter(linear,false)
		con.activate()
		sa.use()
		kri.Ant.inst.quad.draw()

public class FilterCopy(Filter):
	public def constructor():
		sa.add('/copy_v','/copy_f')
		sa.link( kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )


#---------	BLIT BUFFER	--------#

public class Blit( Basic ):
	public def constructor():
		super(true)
	public override def process(con as Context) as void:
		con.copy()
