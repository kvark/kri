namespace kri.lib.par.spa

import OpenTK
import kri.shade

#---	Basic spatial param holder	---#
public class Basic:
	public final position		as par.IBase[of Vector4]
	public final orientation	as par.IBase[of Vector4]
	public def link(d as rep.Dict, n as string) as void:
		d.add(n+'.pos', position)
		d.add(n+'.rot', orientation)
	public def constructor(*var as (par.IBase[of Vector4])):
		position,orientation = var[0],var[1]
	public abstract def activate(n as kri.Node) as void:
		pass


#---	Simple parameter getters	---#
public def getPos(ref s as kri.Spatial) as Vector4:
	return Vector4(s.pos, s.scale)
public def getRot(ref s as kri.Spatial) as Vector4:
	return Vector4(s.rot.Xyz, s.rot.W)


#---	Shared spatial, used for the camera,model,light & bones	---#
public class Shared(Basic):
	public def activate(ref s as kri.Spatial) as void:
		(position		as par.Value[of Vector4]).Value	= getPos(s)
		(orientation	as par.Value[of Vector4]).Value	= getRot(s)
	public override def activate(n as kri.Node) as void:
		s = (n.World if n else kri.Spatial.Identity)
		activate(s)
	public def constructor():
		super( par.Value[of Vector4](), par.Value[of Vector4]() )


#---	Linked value	---#
public class SomeVal( par.IBase[of Vector4] ):
	public node		as kri.Node = null
	public final fun	as callable(ref kri.Spatial) as Vector4
	public Value	as Vector4:
		get:
			assert node and fun
			s = node.World
			return fun(s)
	public def constructor(f as callable(ref kri.Spatial) as Vector4):
		fun = f

#---	Linked spatial to a concrete node, doesn't online interaction	---#
public class Linked(Basic):
	public def constructor():
		super( SomeVal(getPos), SomeVal(getRot) )
	public override def activate(n as kri.Node) as void:
		for sv in (position,orientation):
			(sv as SomeVal).node = n
