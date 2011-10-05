namespace support.defer

#---------	GROUP	--------#

public class Group( kri.rend.Group ):
	public	final	con			as Context
	# renders
	public	final	rFill		as fill.Fork	= null
	public	final	rLayer		as support.layer.Fill	= null
	public	final	rApply		as Apply		= null
	public	final	rParticle	as Particle		= null
	public	final	rBug		as BugLayer		= null
	# signatures
	public	final	sFill	= 'd.fill'
	public	final	sLayer	= 'd.layer'
	public	final	sApply	= 'd.apply'
	public	final	sPart	= 'd.part'
	public	final	sBug	= 'd.bug'
	
	public def constructor(qord as byte, ncone as uint, lc as support.light.Context, pc as kri.part.Context):
		con = cx = Context(qord,ncone)
		rFill	= support.defer.fill.Fork(cx)
		rLayer	= support.layer.Fill(cx)
		rl = List[of kri.rend.Basic]()
		rl.Extend(( rFill, rLayer ))
		if lc:
			rApply = Apply(lc,cx)
			rl.Add(rApply)
		if pc:
			rParticle = Particle(pc,cx)
			rl.Add(rParticle)
		rBug = BugLayer(cx)
		rl.Add(rBug)
		super( *rl.ToArray() )

	public def actNormal(layered as bool) as void:
		rFill.active = not layered
		rLayer.active = layered
		if rParticle:	rParticle.active = true
		if rApply:		rApply.active = true
		
	public def fill(rm as kri.rend.Manager, sZ as string) as void:
		rm.put(sFill,	3,rFill,		sZ)
		rm.put(sLayer,	4,rLayer,		sFill)
		rm.put(sApply,	4,rApply,		sLayer)
		rm.put(sPart,	3,rParticle,	sLayer)
		rm.put(sBug,	1,rBug,			sLayer)
