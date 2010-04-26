namespace kri.part.beh

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

#---------------------------------------#
#	PARTICLE GENERIC BEHAVIOR			#
#---------------------------------------#

public class Basic( kri.meta.IBase, kri.meta.IShaded, Code ):
	public final semantics = List[of kri.vb.attr.Info]()
	[getter(Shader)]
	private final sh		as Object

	public def constructor(path as string):
		super(path)
		sh = Object( ShaderType.VertexShader, path, Text )
	public def constructor(b as Basic):
		super(b)
		semantics.Extend( b.semantics )
		sh = b.sh
	
	public def enrich(size as byte, slot as int) as void:
		semantics.Add( kri.vb.attr.Info(
			integer:false, slot:slot, size:size,
			type:VertexAttribPointerType.Float ))
	
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
	public final parSize	= par.Value[of Vector4]('part_size')
	public final parLife	= par.Value[of Vector4]('part_life')
	public final parVelTan	= par.Value[of Vector4]('part_speed_tan')
	public final parVelObj	= par.Value[of Vector4]('part_speed_obj')
	public final parVelKeep	= par.Value[of Vector4]('object_speed')
	public final parForce	= par.Value[of Vector4]('part_force')
	public final at_sub		= kri.Ant.Inst.slotParticles.getForced('sub')

	public def constructor(pc as kri.part.Context):
		super('/part/beh/main')
		enrich(2, at_sub)
		enrich(3, pc.at_pos)
		enrich(3, pc.at_speed)

	public def constructor(std as Standard):
		super(std)	#is that enough?

	public override def link(d as rep.Dict) as void:
		d.var(parSize,parLife, parVelTan,parVelObj, parVelKeep,parForce)
