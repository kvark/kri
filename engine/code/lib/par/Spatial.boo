namespace kri.lib.par.spa

import OpenTK
import kri.shade
import kri.meta


#---	Shared spatial, used for the camera,model,light & bones	---#
public class Shared(IBase):
	[Getter(Name)]
	private final name	as string
	public final position	as par.Value[of Vector4]
	public final rotation 	as par.Value[of Vector4]
	
	public def constructor(s as string):
		name = s
		position = par.Value[of Vector4](s+'.pos')
		rotation = par.Value[of Vector4](s+'.rot')
	public def activate(ref sp as kri.Spatial) as void:
		position.Value = kri.Spatial.GetPos(sp)
		rotation.Value = kri.Spatial.GetRot(sp)
	public def activate(n as kri.Node) as void:
		sp = (n.World if n else kri.Spatial.Identity)
		activate(sp)
	
	def IBase.clone() as IBase:
		sh = Shared(name)
		sh.position.Value = position.Value
		sh.rotation.Value = rotation.Value
		return sh
	def IBase.link(d as rep.Dict) as void:
		d.var(position,rotation)


#---	Linked value	---#
public class TransVal( par.IBase[of Vector4] ):
	public node			as kri.Node = null
	public final fun	as callable(ref kri.Spatial) as Vector4
	public Value		as Vector4:
		get:
			assert node and fun
			s = node.World
			return fun(s)
	public def constructor(f as callable(ref kri.Spatial) as Vector4):
		fun = f


#---	Linked spatial to a concrete node, doesn't online interaction	---#
public class Linked(IBase):
	[Getter(Name)]
	private final name	as string
	public final position	= TransVal( kri.Spatial.GetPos )
	public final rotation 	= TransVal( kri.Spatial.GetRot )

	public def constructor(s as string):
		name = s
	public def activate(n as kri.Node) as void:
		position.node = rotation.node = n
	public def extract() as kri.Node:
		return position.node

	def IBase.clone() as IBase:
		ln = Linked(name)
		ln.activate( extract() )
		return ln
	def IBase.link(d as rep.Dict) as void:
		d[Name+'.pos']	= position
		d[Name+'.rot']	= rotation
