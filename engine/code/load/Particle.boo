namespace kri.load

import OpenTK

public partial class Native:
	public final pcon =	kri.part.Context()
	public final behavior =	kri.part.Behavior('/part/beh_load')
	public final program = kri.shade.Smart()
	public final sh_draw = kri.shade.Object('/part/draw_load_v')
	
	public def initParticles() as void:
		# main behavior
		ai = kri.vb.attr.Info( integer:false, size:4,
			type: VertexAttribPointerType.Float )
		ai.slot = kri.Ant.Inst.slotParticles.getForced('pos')
		behavior.semantics.Add(ai)
		ai.slot = kri.Ant.Inst.slotParticles.getForced('speed')
		behavior.semantics.Add(ai)
		# draw shader
		program.add( pcon.sh_draw, sh_draw )
		program.add( '/part/draw_simple_f', 'quat', 'tool')
		program.link( kri.Ant.Inst.slotParticles, kri.Ant.Inst.dict )

	public def finishParticles() as void:
		for pe in at.scene.particles:
			pe.man.init(pcon)	if not pe.man.Ready
			pe.init()


	#---	Parse emitter object	---#
	public def p_part() as bool:
		pm = kri.part.Standard( br.ReadUInt32() )
		puData(pm)
		pm.behos.Add( behavior )
		pm.sh_born = pcon.sh_born_time
		pm.parSize.Value = Vector4( getVec2() )
		pe = kri.part.Emitter(pm, getString(), program )
		puData(pe)
		pe.obj = geData[of kri.Entity]()
		at.scene.particles.Add(pe)
		psMat = at.mats[ getString() ]
		psMat = con.mDef	if not psMat
		return true


	#---	Parse distribution		---#	
	public def pp_dist() as bool:
		def upNode(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
		ent = geData[of kri.Entity]()
		source = getString()
		getString()		# type
		br.ReadSingle()	# jitter factor
		pm = geData[of kri.part.Manager]()
		return false	if not pm
		sh as kri.shade.Object	= null
		if source == '':
			sh = pcon.sh_surf_node
			pm.onUpdate = upNode
		elif source == 'VERT':
			return false	if not ent
			for i in range(2):
				t = kri.shade.par.Texture(i, ('vertex','quat')[i] )
				pm.dict.unit(t)
				t.Value = kri.Texture( TextureTarget.TextureBuffer )
				t.Value.bind()
				ats = (kri.Ant.Inst.attribs.vertex, kri.Ant.inst.attribs.quat)
				kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.findAny(ats[i]) )
				pm.onUpdate = upNode
			parNumber = kri.shade.par.Value[of single]( Value: 1f * ent.mesh.nVert )
			pm.dict.add('num_vertices', parNumber)
			sh = pcon.sh_surf_vertex
		elif source == 'FACE':
			tVert = kri.shade.par.Texture(0,'vertex')
			tQuat = kri.shade.par.Texture(1,'quat')
			pm.dict.unit(tVert)
			pm.dict.unit(tQuat)
			if not ent.seTag[of kri.kit.bake.Tag]():
				ent.tags.Add( kri.kit.bake.Tag(256,256, 16,8, false) )
			pm.onUpdate = def(e as kri.Entity):
				upNode(e)
				tag = e.seTag[of kri.kit.bake.Tag]()
				if tag:
					tVert.Value = tag.tVert
					tQuat.Value = tag.tQuat
			sh = pcon.sh_surf_face
		else: assert not 'supported :('
		pm.shaders.Add(sh)
		return true


	#---	Parse life data		---#
	public def pp_life() as bool:
		ps = geData[of kri.part.Standard]()
		return false	if not ps
		data = getVec4()	# start,end, life time, random
		ps.parLife.Value = Vector4( data.Z, data.W, data.X, data.Y )
		return true
	
	#---	Parse velocity setup		---#
	public def pp_vel() as bool:
		ps = geData[of kri.part.Standard]()
		return false	if not ps
		objFactor	= getVector()	# object-aligned factor
		ps.parVelObj.Value = Vector4( objFactor )
		tanFactor	= getVector()	# normal, tangent, tan-phase
		ps.parVelTan.Value = Vector4( tanFactor.Y, 0f, tanFactor.X, tanFactor.Z )
		getVec2()		# object speed, random
		ps.parVelKeep.Value = Vector4.Zero
		return true
	
	public def pp_rot() as bool:
		return true
	
	public def pp_force() as bool:
		ps = geData[of kri.part.Standard]()
		return false	if not ps
		ps.parForceWorld.Value = Vector4(0f,0f,-9.81f,0f)	# gravity only?
		data = getVector()	# brownian, drag, damp
		ps.parForce.Value = Vector4(data)
		return true
