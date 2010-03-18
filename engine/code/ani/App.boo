namespace kri.ani

import System
import OpenTK

###		Counter		###

public class Counter(IBase):
	public final limit	as int
	public count	= 0
	public def constructor(lim as int):
		limit = lim
	def IBase.onFrame(time as double) as uint:
		count = limit	if not count
		--count
		return (2,1)[count>0]


###		Update particles	###

public class Particle(Loop):
	private final pe	as kri.part.Emitter
	public def constructor(em as kri.part.Emitter):
		pe = em
	protected override def onLoop() as void:
		pe.man.reset(pe)
	protected override def onRate(rate as double) as uint:
		pe.man.tick(pe)
		return 0


###		Spatial channel		###

public class Spatial(IBase):
	public final node	as kri.Node
	public final bc		as kri.BoneChannel
	public final lenght	as single
	public final init	as kri.Spatial
	public fromCur		= false
	public def constructor(n as kri.Node, name as string):
		node = n
		ad = n.find(name)
		lenght = ad.length
		bc = ad.channels.Find({ c| return not c.b })
		init = n.Local
	def IBase.onFrame(time as double) as uint:
		sp = bc.moment(time)
		if fromCur:
			s0 = s1 = init
			c0 = bc.c[0].d
			c0.inverse()
			s1.combine(s0,sp)
			sp.combine(s1,c0)
		node.Local = sp
		return (0,1)[time>lenght]


#-------------------------------#
#	Rotate node with mouse		#
#-------------------------------#

public class ControlMouse(IBase):
	private final node	as kri.Node
	private final sense	as single
	private final mouse = kri.Ant.Inst.Mouse
	private active	= false
	private x	= -1
	private y	= -1
	private base	as kri.Spatial
	public def constructor(n as kri.Node, sen as single):
		assert n
		node,sense = n,sen
		mouse.ButtonDown	+= def():
			x = mouse.X
			y = mouse.Y
			base = n.Local
			active = true
		mouse.ButtonUp		+= def():
			active = false
		
	def IBase.onFrame(time as double) as uint:
		return 0	if not active

		dx = cast(single, mouse.X-x)
		dy = cast(single, mouse.Y-y)
		axis	= Vector3(dy, dx, 0f)
		size	= sense * axis.LengthFast
		
		qrot	= Quaternion.FromAxisAngle(axis, size)
		s		= kri.Camera.current.node.World
		qrot	= s.rot * qrot * Quaternion.Invert(s.rot)
		s		= base
		s.rot	= qrot * s.rot
		node.Local = s
		return 0
