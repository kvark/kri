namespace support.corp.beh

import OpenTK
import kri.shade
import kri.part


public class Sys(Behavior):	# at_sys storage for standard root
	public def constructor(pc as kri.part.Context):
		super('/part/beh/sys')
		kri.Help.enrich( self, 2, pc.at_sys )


public class Pad(Behavior):	# padding for rgba32f align
	public static final	slot	= kri.Ant.Inst.slotParticles.getForced('pad')
	public def constructor():
		super('/part/beh/pad')
		kri.Help.enrich( self, 1, slot )


public class Norm(Behavior):	# fur normalizing
	public def constructor():
		super('/part/beh/fur_norm')


#---	 SIMULATION		---#

public class Physics(Behavior):
	public final pSize	= par.Value[of Vector4]('part_size')
	public final pForce	= par.Value[of Vector4]('port_force')
	public override def link(d as rep.Dict) as void:
		d.var(pSize,pForce)


#---	 GRAVITY	---#

public class Gravity(Behavior):
	public final par	as par.Value[of Vector4]
	public def constructor(pg as par.Value[of Vector4]):
		super('/part/beh/grav')
		par = pg
	public override def link(d as rep.Dict) as void:
		d.var(par)


#-------------------------------------------#
#	SIMPLE BEHAVIOR BASE					#
#-------------------------------------------#

public class Simple[of T(struct)](Behavior):
	public final pData	as par.Value[of T]
	public def constructor(path as string, varname as string, data as T):
		super(path)
		pData = par.Value[of T](varname)
		pData.Value = data
	public override def link(d as rep.Dict) as void:
		d.var(pData)


#-------------------------------------------#
#	SMALL  BEHAVIORS						#
#-------------------------------------------#

public class Damp(Simple[of single]):		# speed damping
	public def constructor(val as single):
		super('/part/beh/damp','speed_damp',val)

public class Stiff(Simple[of single]):		# fur stiffness
	public def constructor(val as single):
		super( '/part/beh/fur_stiff','fur_stiff',val)

public class Rotate(Simple[of single]):		# particle rotation
	public def constructor(val as single, pc as kri.part.Context):
		super('/part/beh/rotate','part_spin', val)
		kri.Help.enrich( self, 4, pc.at_rot )
