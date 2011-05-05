namespace support.light.group

import support.light


public class Forward( kri.rend.Group ):
	public	final	con			as Context
	public	final	rSpotFill	as spot.Fill
	public	final	rSpotApply	as spot.Apply
	public	final	rOmniFill	as omni.Fill
	public	final	rOmniApply	as omni.Apply

	public def constructor(qord as byte, smooth as bool):
		con = Context(0,qord)
		rSpotFill	= spot.Fill(con)
		rSpotApply	= spot.Apply(con)
		rOmniFill	= omni.Fill(con)
		rOmniApply	= omni.Apply(con,smooth)
		super(rSpotFill,rOmniFill,rSpotApply,rOmniApply)
