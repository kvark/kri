namespace support.light.group

import support.light


public class Forward( kri.rend.Group ):
	public	final	con			as Context
	public	final	rSpotFill	as Fill
	public	final	rSpotApply	as Apply
	public	final	rOmniFill	as omni.Fill
	public	final	rOmniApply	as omni.Apply
	public	final	rParticle	as kri.rend.part.Standard	= null

	public def constructor(qord as byte, smooth as bool, pc as kri.part.Context):
		con = Context(0,qord)
		rSpotFill	= Fill(con)
		rSpotApply	= Apply(con)
		rOmniFill	= omni.Fill(con)
		rOmniApply	= omni.Apply(smooth)
		rl = List[of kri.rend.Basic]((rSpotFill,rOmniFill,rSpotApply,rOmniApply))
		if pc:	rl.Add( kri.rend.part.Standard(pc) )
		super( *rl.ToArray() )
