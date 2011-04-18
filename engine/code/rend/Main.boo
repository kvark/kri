namespace kri.rend

import System.Collections.Generic


#---------	BASIC RENDER	--------#

public class Basic:
	public	active	as bool = true
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
			if r.active:
				r.process(ln)
		if con:
			ln.blitTo(con)


#---------	GENERAL FILTER	--------#

public class Filter(Basic):
	protected	final bu	= kri.shade.Bundle()
	protected	final texIn	= kri.shade.par.Texture('input')
	protected	final dict	= kri.shade.par.Dict()
	protected	linear		= false
	
	public def constructor():
		dict.unit(texIn)
		bu.dicts.Add(dict)
	public override def process(con as link.Basic) as void:
		texIn.Value = con.Input
		con.Input.filt(linear,false)
		con.activate(true)
		kri.Ant.inst.quad.draw(bu)

public class FilterCopy(Filter):
	public def constructor():
		bu.shader.add('/copy_v','/copy_f')


#---------	RENDER GROUP	--------#

public class Group(Basic):
	public	abstract	All	as (Basic):
		get: pass
	public override def setup(pl as kri.buf.Plane) as bool:
		return System.Array.TrueForAll(All) do(r as Basic):
			return r.setup(pl)
	public override def process(con as link.Basic) as void:
		for r in All:
			r.process(con)
