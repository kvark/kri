namespace kri.ani.sim

import System
import OpenTK
#import NewtonWrapper

#-----------------------#
#	PHYSICS SECTION		#
#-----------------------#

public interface IField:
	def effect(ref s as kri.Spatial) as Vector3:
		pass


public class Basic(kri.ani.Delta):
	public final scene		as kri.Scene
	public final fLinear	= List[of IField]()
	public final fAngular	= List[of IField]()
	public def constructor(s as kri.Scene):
		scene = s
	private abstract def assembly(ref s as kri.Spatial, d as double,
			b as kri.Body, *v as (Vector3)) as void:
		pass
	protected override def onDelta(delta as double) as uint:
		for b in scene.bodies:
			lin = ang = Vector3(0f,0f,0f)
			s = b.node.Local
			for f in fLinear:
				lin += f.effect(s)
			for f in fAngular:
				ang += f.effect(s)
			assembly(s, delta, b, lin,ang)
			b.node.Local = s
		return 0


public class Native(Basic):
	public def constructor(s as kri.Scene):
		super(s)
	private override def assembly(ref s as kri.Spatial, d as double,
			b as kri.Body, *v as (Vector3)) as void:
		b.vLinear	+= d*v[0]
		b.vAngular	+= d*v[1]
		s.pos += d * b.vLinear
		s.rot += Quaternion(Xyz: 0.5f*d*b.vAngular, W:0f) * s.rot
		s.rot.Normalize()


public class Render(Native):
	public final pr	as	kri.rend.Physics
	public def constructor(s as kri.Scene, ord as int):
		super(s)
		pr = kri.rend.Physics(ord)
	protected override def onDelta(delta as double) as uint:
		super(delta)
		#pr.tick(scene)
		return 0


public class Newton(Basic):
	#private final world	= Newton.Create(0,0)
	public def constructor(s as kri.Scene):
		super(s)
	protected override def onDelta(delta as double) as uint:
		super(delta)
		#Newton.Update(world, cast(single,delta))
		return 0
	private override def assembly(ref s as kri.Spatial, d as double,
			b as kri.Body, *v as (Vector3)) as void:
		b.vLinear	+= d*v[0]
		b.vAngular	+= d*v[1]
		s.pos += d * b.vLinear
		s.rot += Quaternion(Xyz: 0.5f*d*b.vAngular, W:0f) * s.rot
		s.rot.Normalize()
