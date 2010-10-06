namespace support.corp.inst

import System.Collections.Generic
import OpenTK


public class Meta( kri.meta.Advanced ):
	public ent	as kri.Entity	= null
	def System.ICloneable.Clone() as object:
		return copyTo( Meta( ent:ent ))
	def kri.meta.IBase.link(d as kri.shade.rep.Dict) as void:
		pass


public class Rend( kri.rend.tech.Meta ):
	private final trans		= Dictionary[of int,int]()
	private cur	as kri.part.Emitter	= null
	private final pBase		= kri.shade.par.Value[of Vector4]('base_color')
	
	public def constructor(pc as kri.part.Context):
		super('part.object', false, null, 'emissive')
		# attributes
		trans[ pc.at_pos ] = pc.ghost_pos
		trans[ pc.at_rot ] = pc.ghost_rot
		trans[ pc.at_sys ] = pc.ghost_sys
		trans[ pc.at_sub ] = pc.ghost_sub
		# shade
		pBase.Value = Vector4.UnitX
		dict.var(pBase)
		shade(( '/part/draw/obj_v', '/mat_base_f' ))

	/*# blocked by BOO-963
	protected override def getUpdate(mat as kri.Material) as callable() as int:
		pe = cur
		return def() as int:
			for at in trans.Values:
				GL.Arb.VertexAttribDivisor(at,1)
			pe.data.attribTrans(trans)
			return pe.owner.total*/
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(true,0f,true)
		butch.Clear()
		for pe in kri.Scene.Current.particles:
			continue	if not pe.mat
			inst = pe.mat.Meta['inst'] as Meta
			continue	if not inst
			ent = inst.ent
			continue	if not ent
			pats = List[of int](sem.slot	for sem in pe.data.Semant)
			continue	if not List[of int](trans.Keys).TrueForAll({at| return at in pats })
			cur = pe
			addObject(ent)
		for b in butch:
			b.draw()
