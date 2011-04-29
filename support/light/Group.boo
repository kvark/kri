namespace support.light.group

import support.light


public class Forward( kri.rend.Group ):
	public	final	con			as Context
	public	final	rSpotFill	as Fill
	public	final	rSpotApply	as Apply
	public	final	rOmniFill	as omni.Fill
	public	final	rOmniApply	as omni.Apply

	public def constructor(qord as byte, smooth as bool):
		con = Context(0,qord)
		rSpotFill	= Fill(con)
		rSpotApply	= Apply(con)
		rOmniFill	= omni.Fill(con)
		rOmniApply	= omni.Apply(smooth)
		super(rSpotFill,rOmniFill,rSpotApply,rOmniApply)
