namespace kri.rend

import System.Collections.Generic
import OpenTK.Graphics.OpenGL

#---------	RENDER CHAIN MANAGER	--------#

public class Chain(Basic):
	public	final	renders	= List[of Basic]()		# *Render
	public	final	ln		as link.Buffer
	public	doProfile		as bool	= false
	private	final	dpro	= Dictionary[of Basic,kri.Query]()
	
	public def constructor():
		ln = link.Buffer(0,0,0)
	public def constructor(ns as byte, bc as byte, bd as byte):
		ln = link.Buffer(ns,bc,bd)
	
	public override def setup(pl as kri.buf.Plane) as bool:
		ln.resize(pl)
		return renders.TrueForAll() do(r as Basic):
			return r.setup(pl)
		
	public override def process(con as link.Basic) as void:
		if not ln.Ready:
			return
		dpro.Clear()
		for r in renders:
			if not r.active:	continue
			if doProfile:
				dpro[r] = q = kri.Query( QueryTarget.TimeElapsed )
				using q.catch():
					r.process(ln)
			else:	r.process(ln)
		if con:
			ln.blitTo(con)
	
	public def genReport() as string:
		rez = 'Profile report:'
		for p in dpro:
			name = p.Key.ToString()
			time = p.Value.result()
			rez += "\n${name}: ${time}"
		return rez
