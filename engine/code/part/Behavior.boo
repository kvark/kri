namespace kri.part

import OpenTK.Graphics.OpenGL
import kri.shade

#---------------------------------------#
#	PARTICLE GENERIC BEHAVIOR			#
#---------------------------------------#

public class Behavior( kri.meta.IBase ):
	public final code	as string
	public final semantics = List[of kri.vb.attr.Info]()
	public final sh		as Object

	public def constructor(path as string):
		code = kri.shade.Object.readText(path)
		sh = kri.shade.Object( ShaderType.VertexShader, 'beh', code )
	public def constructor(b as Behavior):
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
	
	public virtual def link(d as rep.Dict) as void:
		pass
	def kri.meta.IBase.clone() as kri.meta.IBase:
		return Behavior(self)
	par.INamed.Name:
		get: return 'behavior'


#---------------------------------------------------#
#	STANDARD BEHAVIOR FOR LOADED PARTICLES			#
#---------------------------------------------------#

public class Standard(Behavior):
	public final parSize	= par.Value[of OpenTK.Vector4]()
	public final parLife	= par.Value[of OpenTK.Vector4]()
	public final parVelTan	= par.Value[of OpenTK.Vector4]()
	public final parVelObj	= par.Value[of OpenTK.Vector4]()
	public final parVelKeep	= par.Value[of OpenTK.Vector4]()
	public final parForce	= par.Value[of OpenTK.Vector4]()
	public final parForceWorld	= par.Value[of OpenTK.Vector4]()

	public def constructor():
		super('/part/beh/main')
		# setup attributes
		ai = kri.vb.attr.Info( integer:false, size:4,
			type: VertexAttribPointerType.Float )
		ai.slot = kri.Ant.Inst.slotParticles.getForced('pos')
		semantics.Add(ai)
		ai.slot = kri.Ant.Inst.slotParticles.getForced('speed')
		semantics.Add(ai)
	
	public def constructor(std as Standard):
		super(std)

	public override def link(d as rep.Dict) as void:
		d.add('part_size',		parSize)
		d.add('part_life',		parLife)
		d.add('part_speed_tan',	parVelTan)
		d.add('part_speed_obj',	parVelObj)
		d.add('object_speed',	parVelKeep)
		d.add('part_force',		parForce)
		d.add('force_world', 	parForceWorld)
