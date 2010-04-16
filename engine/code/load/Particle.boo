namespace kri.load

import OpenTK

public partial class Native:
	public final pcon =	kri.part.Context()
	public final behavior	= kri.part.beh.Standard()
	public final halo_draw_v	= kri.shade.Object('/part/draw_load_v')
	public final halo_draw_f	= kri.shade.Object('/part/draw_load_f')
	public final partFactory	= kri.shade.Linker(\
		kri.Ant.Inst.slotParticles, kri.Ant.Inst.dict )
	
	public def initParticles() as void:
		partFactory.onLink = do(sa as kri.shade.Smart):
			sa.add( pcon.sh_draw, halo_draw_v, halo_draw_f )
			sa.add( 'quat', 'tool')

	public def finishParticles() as void:
		for pe in at.scene.particles:
			pe.man.init(pcon)	if not pe.man.Ready
			mat = con.mDef
			for m in at.mats.Values:
				if pe.halo in m.metaList:
					mat = m
					break
			pe.sa = partFactory.link( (pe.halo.Shader,), mat.dict )
		


	#---	Parse emitter object	---#
	public def p_part() as bool:
		pm = kri.part.Manager( br.ReadUInt32() )
		puData(pm)
		beh = kri.part.beh.Standard(behavior)
		puData(beh)
		pm.behos.Add( beh )
		pm.sh_born = pcon.sh_born_time
		beh.parSize.Value = Vector4( getVec2() )
		name = getString()
		# link to material
		psMat = at.mats[ getString() ]
		psMat = con.mDef	if not psMat.Meta['halo']
		halo = psMat.Meta['halo'] as kri.meta.Halo
		return false	if not halo
		# create emitter
		pe = kri.part.Emitter(pm,name)
		puData(pe)
		pe.obj = geData[of kri.Entity]()
		at.scene.particles.Add(pe)
		pe.halo = halo
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
				t = kri.shade.par.Value[of kri.Texture]( ('vertex','quat')[i] )
				pm.dict.unit(t.Name,t)
				t.Value = kri.Texture( TextureTarget.TextureBuffer )
				t.Value.bind()
				ats = (kri.Ant.Inst.attribs.vertex, kri.Ant.inst.attribs.quat)
				kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.findAny(ats[i]) )
				pm.onUpdate = upNode
			parNumber = kri.shade.par.Value[of single]('num_vertices')
			parNumber.Value = 1f * ent.mesh.nVert
			pm.dict.var(parNumber)
			sh = pcon.sh_surf_vertex
		elif source == 'FACE':
			tVert = kri.shade.par.Value[of kri.Texture]('vertex')
			tQuat = kri.shade.par.Value[of kri.Texture]('quat')
			pm.dict.unit(tVert,tQuat)
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
		ps = geData[of kri.part.beh.Standard]()
		return false	if not ps
		data = getVec4()	# start,end, life time, random
		ps.parLife.Value = Vector4( data.Z, data.W, data.Y-data.X, 1f )
		return true
	
	#---	Parse velocity setup		---#
	public def pp_vel() as bool:
		ps = geData[of kri.part.beh.Standard]()
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
		ps = geData[of kri.part.beh.Standard]()
		return false	if not ps
		ps.parForceWorld.Value = Vector4(0f,0f,-9.81f,0f)	# gravity only?
		data = getVector()	# brownian, drag, damp
		ps.parForce.Value = Vector4(data)
		return true
