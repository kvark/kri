namespace kri.part.beh

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

#---------------------------------------#
#	PARTICLE GENERIC BEHAVIOR			#
#---------------------------------------#

public class Basic( kri.meta.IBase ):
	public final code	as string
	public final semantics = List[of kri.vb.attr.Info]()
	public final sh		as Object

	public def constructor(path as string):
		code = kri.shade.Object.readText(path)
		sh = kri.shade.Object( ShaderType.VertexShader, 'beh', code )
	public def constructor(b as Basic):
		code = b.code
		semantics.Extend( b.semantics )
		sh = b.sh
	
	public def getMethod(base as string) as string:
		return null	if string.IsNullOrEmpty(code)
		pos = code.IndexOf(base)
		return null	if pos<0
		p2 = code.IndexOf('()',pos)
		assert p2>=0
		return code.Substring(pos,p2+2-pos)
	
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
