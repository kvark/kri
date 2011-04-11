﻿namespace support.skin

#---------	RENDER SKELETON SYNC		--------#

public class Update( kri.rend.tech.Basic ):
	private final va	= kri.vb.Array()
	private final tf	= kri.TransFeedback(1)
	private final bu	= kri.shade.Bundle()
	private final par	= List[of kri.lib.par.spa.Shared](
		kri.lib.par.spa.Shared("bone[${i}]")
		for i in range(kri.Ant.Inst.caps.bones)
		).ToArray()
	public final at_mod	= ('vertex','quat')
	public final at_all	as (int)

	public def constructor(dq as bool):
		super('skin')
		dict = kri.shade.par.Dict()
		for p as kri.meta.IBase in par:
			p.link(dict)
		# prepare shader
		sa = bu.shader
		sa.add( '/lib/quat_v', '/skin/skin_v', '/skin/main_v' )
		sa.add( ('/skin/simple_v','/skin/dual_v')[dq] )
		#old: sa.add( '/skin/zcull_v', '/lib/tool_v', '/empty_f' )
		sa.add( '/skin/empty_v' )
		sa.feedback(true, 'to_vertex', 'to_quat')
		bu.dicts.Add(dict)
		# finish
		spat = kri.Spatial.Identity
		par[0].activate(spat)

	public override def process(con as kri.rend.link.Basic) as void:
		if not kri.Scene.Current:	return
		for e in kri.Scene.Current.entities:
			kri.Ant.Inst.params.modelView.activate( e.node )
			tag = e.seTag[of Tag]()
			if not e.visible or not tag or tag.Sync:
				continue
			# collect or create destination buffers
			vos = array[of kri.vb.Attrib]( at_mod.Length )
			for i in range( vos.Length ):
				vos[i] = e.store.find(at_mod[i])
				if vos[i]:	continue
				orig = e.mesh.find(at_mod[i])
				assert orig
				ai = orig.Semant[0]
				vos[i] = v = kri.vb.Attrib()
				v.Semant.Add(ai)
				v.init( e.mesh.nVert * ai.fullSize() )
				e.store.vbo.Add(v)
			tf.Bind( *vos )
			# run the transform
			spa as kri.Spatial
			for i in range( tag.skel.bones.Length ):
				b = tag.skel.bones[i]	# model->pose
				b.genTransPose( e.node.local, spa )
				s0 = s1 = b.World
				s0.combine(spa,s1)	# ->world
				s1 = e.node.World
				s1.inverse()
				spa.combine(s0,s1)	# ->model
				par[i+1].activate(spa)
			using kri.Discarder(true):
				e.mesh.render(va,bu,tf)
			tag.Sync = true
