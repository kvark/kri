namespace support.light.group

import support.light


public class Forward(kri.rend.Group):
	public	final	con			= Context(0,8)
	public	final	rSpotFill	= Fill(con)
	public	final	rSpotApply	= Apply(con)
	public	final	rOmniFill	= omni.Fill(con)
	public	final	rOmniApply	= omni.Apply(false)
	public	override All	as (kri.rend.Basic):
		get: return (of kri.rend.Basic: rSpotFill,rOmniFill,rSpotApply,rOmniApply)
