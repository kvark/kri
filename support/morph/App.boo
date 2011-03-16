namespace support.morph

import System.Collections.Generic
import OpenTK

#----------------------------------------
#	Animation of morphing between to shapes

public class Anim( kri.ani.Loop ):
	public final k0	as Tag
	public final k1	as Tag
	public def constructor(e as kri.Entity, s0 as string, s1 as string):
		assert s0 and s1 and s0!=s1
		k0 = k1 = null
		for key in e.enuTags[of Tag]():
			k0 = key	if key.name == s0
			k1 = key	if key.name == s1
		assert k0 and k1
	protected override def onRate(rate as double) as void:
		k0.Value = 1.0 - rate
		k1.Value = rate


#----------------------------------------
#	Update render, puts the morph result into the mesh data

public class Update( kri.rend.Basic ):
	public final tf		= kri.TransFeedback(1)
	public final bu		= kri.shade.Bundle()
	public final pVal	= kri.shade.par.Value[of Vector4]('shape_value')
	private final va	= kri.vb.Array()
	private final slot	= kri.lib.Slot(4)
	private final eps	= 1.0e-7
	public def constructor():
		slot.create('pos')
		for i in range(4):
			slot.create('pos'+(i+1))
		d = kri.shade.rep.Dict()
		d.var(pVal)
		bu.shader.add('/skin/morph_v')
		bu.shader.feedback(true,'to_pos')
		bu.dicts.Add(d)
	
	public override def process(con as kri.rend.link.Basic) as void:
		trans = Dictionary[of string,string]()
		va.bind()
		using kri.Discarder(true):
			for ent in kri.Scene.Current.entities:
				keys = ent.enuTags[of Tag]()
				dirty = System.Array.Find(keys) do(t as Tag):
					return t.Dirty
				continue	if keys.Length<2 or not dirty
				assert ent.mesh
				pVal.Value = Vector4( keys[0].Value, keys[1].Value, 0f,0f )
				sum = Vector4.Dot( pVal.Value, Vector4.One )
				pVal.Value.X += 1f-sum
				#assert System.Math.Abs(sum-1f) < eps
				# bind attribs & draw
				#ent.enable(false, (av,))
				trans['vertex'] = ''
				for i in range( System.Math.Min(4,keys.Length) ):
					pass
					#trans['vertex'] = i+1
					#keys[i].data.attribTrans(trans)	#support?
				#tf.Bind( ent.mesh.find( kri.Ant.Inst.attribs.vertex ))	#?
				assert not 'supported' # trans attributes?
				#bu.activate()
				#ent.mesh.draw(tf)
