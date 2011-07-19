namespace support.light.group

import support.light


public class Forward( kri.rend.Group ):
	public	final	con			as Context
	# renders
	public	final	rEmi		= kri.rend.Emission()
	public	final	rSpotFill	as spot.Fill
	public	final	rSpotApply	as spot.Apply
	public	final	rOmniFill	as omni.Fill
	public	final	rOmniApply	as omni.Apply
	# signatures
	public	final	sEmi	= 'emi'
	public	final	ssFill	= 's.fill'
	public	final	ssApply	= 's.apply'
	public	final	soFill	= 'o.fill'
	public	final	soApply	= 'o.apply'
	
	public	BaseColor 	as OpenTK.Graphics.Color4:
		set:	rEmi.pBase.Value = value

	public def constructor(qord as byte, smooth as bool):
		con = Context(0,qord)
		rSpotFill	= spot.Fill(con)
		rSpotApply	= spot.Apply(con)
		rOmniFill	= omni.Fill(con)
		rOmniApply	= omni.Apply(con,smooth)
		super(rEmi,rSpotFill,rOmniFill,rSpotApply,rOmniApply)
	
	public def fill(rm as kri.rend.Manager, skin as string, sZ as string) as void:
		rm.put(sEmi,	3,rEmi,			skin,sZ)
		rm.put(ssFill,	3,rSpotFill,	skin)
		rm.put(ssApply,	3,rSpotApply,	ssFill,sZ)
		rm.put(soFill,	4,rOmniFill,	skin)
		rm.put(soApply,	3,rOmniApply,	soFill,sZ)
