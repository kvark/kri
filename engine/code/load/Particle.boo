namespace kri.load

import OpenTK

public partial class Native:
	public final pcon =	kri.part.Context()
	
	#---	Parse particle object	---#
	public def p_part() as bool:
		pm = kri.part.ManStandard( br.ReadUInt32() )
		puData(pm)
		pm.parSize.Value = Vector4( getVec2() )
		pe = kri.part.Emitter(pm, getString() )
		puData(pe)
		at.scene.particles.Add(pe)
		psMat = at.mats[ getString() ]
		psMat = con.mDef	if not psMat
		return true
	
	public def pp_dist() as bool:
		br.ReadByte()	# type
		br.ReadSingle()	# jitter factor
		if 'emitting from the mesh surface':
			e = geData[of kri.Entity]()
			return false	if not e
			assert 'not ready'
			#pe.onUpdate = { kri.Ant.Inst.units.activate(e.unit) }
		return true
	
	public def pp_life() as bool:
		getVec4()	# start,end, life time, random
		return true
	
	public def pp_vel() as bool:
		getVector()	# object-aligned factor
		getVector()	# normal, tangent, tan-phase
		getVec2()	# object speed, random
		return true
	
	public def pp_rot() as bool:
		return true
	
	public def pp_force() as bool:
		getVector()	# brownian, drag, damp
		return true
