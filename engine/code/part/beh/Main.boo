namespace kri.part.beh

import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

#---------------------------------------#
#	PARTICLE GENERIC BEHAVIOR			#
#---------------------------------------#

public class Basic( kri.meta.IBase, kri.meta.IShaded, kri.vb.ISemanted, Code ):
	[Getter(Semant)]
	private final semantics	as List[of kri.vb.Info]	= List[of kri.vb.Info]()
	[getter(Shader)]
	private final sh		as Object

	public def constructor():
		super( CodeNull() )
		sh = null
	public def constructor(path as string):
		super(path)
		sh = Object( ShaderType.VertexShader, path, Text )
	public def constructor(b as Basic):
		super(b)
		semantics.AddRange( b.Semant )
		sh = b.sh
	
	public virtual def link(d as rep.Dict) as void:
		pass
	def kri.meta.IBase.clone() as kri.meta.IBase:
		return Basic(self)
	par.INamed.Name:
		get: return 'behavior'



#-------------------------------------------#
#	STANDARD FOR LOADED PARTICLES			#
#-------------------------------------------#

public class Standard(Basic):
	public final parLife	= par.Value[of Vector4]('part_life')
	public final parVelTan	= par.Value[of Vector4]('part_speed_tan')
	public final parVelObj	= par.Value[of Vector4]('part_speed_obj')
	public final parVelKeep	= par.Value[of Vector4]('object_speed')

	public def constructor(pc as kri.part.Context):
		super('/part/beh/main')
		kri.Help.enrich( self, 2, pc.at_sub )
		kri.Help.enrich( self, 3, pc.at_pos, pc.at_speed )

	public def constructor(std as Standard):
		super(std)	#is that enough?

	public override def link(d as rep.Dict) as void:
		d.var(parLife, parVelTan, parVelObj, parVelKeep)
