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
	private final trans		= Dictionary[of string,string]()
	private cur	as kri.part.Emitter	= null
	private final pBase		= kri.shade.par.Value[of Vector4]('base_color')
	
	public def constructor(pc as kri.part.Context):
		super('part.object', false, null, 'emissive')
		# attributes
		for str in ('pos','rot','sys','sub'):
			trans[str] = '@'+str
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
	
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate( con.Target.Same, 0f, true )
		butch.Clear()
		for pe in kri.Scene.Current.particles:
			continue	if not pe.mat
			inst = pe.mat.Meta['inst'] as Meta
			continue	if not inst
			ent = inst.ent
			continue	if not ent
			assert not 'supported'
			#pats = List[of string](sem.name	for sem in pe.data.Semant)
			#continue	if not List[of string](trans.Keys).TrueForAll({at| return at in pats })
			cur = pe
			addObject(ent)
		for b in butch:
			b.draw()
