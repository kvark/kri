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

public class Particle( IBase ):
	private final pe	as kri.part.Emitter
	private ready		as bool	= false
	public def constructor(ps as kri.part.Emitter):
		pe = ps
	def kri.ani.IBase.onFrame(time as double) as uint:
		if ready: pe.owner.tick(pe)
		else: ready = pe.owner.reset(pe)
		return 0


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
			base = n.local
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
		n		= kri.Camera.current.node
		s		= (n.World	if n else kri.Spatial.Identity)
		qrot	= s.rot * qrot * Quaternion.Invert(s.rot)
		s		= base
		s.rot	= qrot * s.rot
		node.local = s
		node.touch()
		return 0
