namespace kri.kit.morph

import System
import System.Collections.Generic

public class Main:
	public final tar	= Dictionary[of string,kri.Mesh]()
	public static final ats	= (kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat)
	public final va		= kri.vb.Array()
	public final sa		= kri.shade.Smart()
	public final pTime	= kri.shade.par.Value[of single]()
	public final tf		= kri.TransFeedback(1)
	public static final max	=	4

	public def apply(mar as (kri.Mesh), t as single) as void:
		va.bind()
		pTime.Value = t
		for i in range( Math.Min(max,mar.Length-1) ):
			m = mar[i+1]
			assert m.nVert == mar[0].nVert
			for j in range(ats.Length):
				m.find(ats[j]).attribFake(max*j+i)
		sa.use()
		mar[0].draw(tf)
