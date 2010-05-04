namespace kri.rend.part

import System
import System.Collections.Generic
import OpenTK
import OpenTK.Graphics.OpenGL


public class Inst( kri.rend.tech.Meta ):
	private final trans		= Dictionary[of int,int]()
	private cur	as kri.part.Emitter	= null
	private final pBase		= kri.shade.par.Value[of Vector4]('base_color')
	
	public def constructor(pc as kri.part.Context):
		super('part.object', false, null, 'emissive')
		pBase.Value = Vector4.UnitX
		dict.var(pBase)
		shade(( '/part/draw/obj_v', '/mat_base_f' ))
		# attributes
		trans[ pc.at_sys ] = pc.trans_sys
		trans[ pc.at_pos ] = pc.trans_pos
		trans[ pc.at_sub ] = pc.trans_sub
		extList.AddRange( trans.Values )

	protected override def getUpdate(mat as kri.Material) as callable() as int:
		pe = cur
		return def() as int:
			for at in extList:
				GL.Arb.VertexAttribDivisor(at,1)
			pe.data.attribTrans(trans)
			return pe.owner.total
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(true,0f,true)
		butch.Clear()
		for pe in kri.Scene.Current.particles:
			continue	if not pe.mat
			inst = pe.mat.Meta['inst'] as kri.meta.Inst
			continue	if not inst
			ent = inst.ent
			continue	if not ent
			pats = array(sem.slot	for sem in pe.data.Semant)
			continue	if not Array.TrueForAll(
				array(trans.Keys),	{at| return at in pats })
			cur = pe
			addObject(ent)
		for b in butch:
			b.draw()
