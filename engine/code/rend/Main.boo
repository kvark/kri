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
	public virtual def setup(pl as kri.buf.Plane) as bool:
		return true
	public virtual def process(con as link.Basic) as void:
		pass


#---------	RENDER CHAIN MANAGER	--------#

public class Chain(Basic):
	public final	renders	= List[of Basic]()		# *Render
	public final	ln		as link.Buffer
	
	public def constructor():
		ln = link.Buffer(0,0,0)
	public def constructor(ns as byte, bc as byte, bd as byte):
		ln = link.Buffer(ns,bc,bd)
	
	public override def setup(pl as kri.buf.Plane) as bool:
		ln.resize(pl)
		return renders.TrueForAll() do(r as Basic):
			return r.setup(pl)
		
	public override def process(con as link.Basic) as void:
		for r in renders:
			r.process(ln)	if r.active
		ln.blitTo(con)


#---------	GENERAL FILTER	--------#

public class Filter(Basic):
	protected final sa		= kri.shade.Smart()
	protected final texIn	= kri.shade.par.Texture('input')
	protected final dict	= kri.shade.rep.Dict()
	protected linear		= false
	public def constructor():
		super(true)
		dict.unit(texIn)
	public override def process(con as link.Basic) as void:
		texIn.Value = con.Input
		con.Input.filt(linear,false)
		con.activate(true)
		sa.use()
		kri.Ant.inst.quad.draw()

public class FilterCopy(Filter):
	public def constructor():
		sa.add('/copy_v','/copy_f')
		sa.link( kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
