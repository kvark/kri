namespace kri.load

import OpenTK

public struct SetBake:
	public width	as uint
	public height	as uint
	public b_pos	as byte
	public b_rot	as byte
	public filt		as bool
	public def tag() as kri.ITag:
		return kri.kit.bake.Tag(width,height,b_pos,b_rot,filt)

public partial class Settings:
	public bake		= SetBake( width:256, height:256, b_pos:16, b_rot:8, filt:false )



public partial class Native:
	public final pcon =	kri.part.Context()
	/*
	public final halo_draw_v	= kri.shade.Object('/part/draw/load_v')
	public final halo_draw_f	= kri.shade.Object('/part/draw/load_f')
	public final partFactory	= kri.shade.Linker(\
		kri.Ant.Inst.slotParticles, kri.Ant.Inst.dict )
	
	public def initParticles() as void:
		partFactory.onLink = do(sa as kri.shade.Smart):
			sa.add( pcon.sh_draw, pcon.sh_tool, halo_draw_v, halo_draw_f )
			sa.add( 'quat', 'tool')
	*/
	public def finishParticles() as void:
		for pe in at.scene.particles:
			pe.owner.init(pcon)	if not pe.owner.Ready
			#pe.sa = partFactory.link( (pe.halo.Shader,), mat.dict )
		


	#---	Parse emitter object	---#
	public def p_part() as bool:
		pm = kri.part.Manager( br.ReadUInt32() )
		puData(pm)
		beh = kri.part.beh.Standard(pcon)
		puData(beh)
		pm.behos.Add( kri.part.beh.Sys(pcon) )
		pm.behos.Add( beh )
		pm.shaders.Add( pcon.sh_born_time )
		pm.sh_root = pcon.sh_root
		beh.parSize.Value = Vector4( getVec2() )
		# # create emitter
		pe = kri.part.Emitter( pm, getString() )
		puData(pe)
		pe.obj = geData[of kri.Entity]()
		at.scene.particles.Add(pe)
		# link to material
		pe.mat = at.mats[ getString() ]
		pe.mat = con.mDef	if not pe.mat
		return true


	#---	Parse distribution		---#
	public def pp_dist() as bool:
		def upNode(e as kri.Entity):
			assert e
			kri.Ant.Inst.params.modelView.activate( e.node )
			return true
		ent = geData[of kri.Entity]()
		source = getString()
		getString()		# type
		br.ReadSingle()	# jitter factor
		pm = geData[of kri.part.Manager]()
		pe = geData[of kri.part.Emitter]()
		return false	if not pm or not pe
		sh as kri.shade.Object	= null
		if source == '':
			sh = pcon.sh_surf_node
			pe.onUpdate = upNode
		elif source == 'VERT':
			return false	if not ent
			for i in range(2):
				t = kri.shade.par.Value[of kri.Texture]( ('vertex','quat')[i] )
				pm.dict.unit(t.Name,t)
				t.Value = kri.Texture( TextureTarget.TextureBuffer )
				t.Value.bind()
				ats = (kri.Ant.Inst.attribs.vertex, kri.Ant.inst.attribs.quat)
				kri.Texture.Init( SizedInternalFormat.Rgba32f, ent.findAny(ats[i]) )
				pe.onUpdate = upNode
			parNumber = kri.shade.par.Value[of single]('num_vertices')
			parNumber.Value = 1f * ent.mesh.nVert
			pm.dict.var(parNumber)
			sh = pcon.sh_surf_vertex
		elif source == 'FACE':
			tVert = kri.shade.par.Value[of kri.Texture]('vertex')
			tQuat = kri.shade.par.Value[of kri.Texture]('quat')
			pm.dict.unit(tVert,tQuat)
			if not ent.seTag[of kri.kit.bake.Tag]():
				ent.tags.Add( sets.bake.tag() )
			pe.onUpdate = def(e as kri.Entity):
				upNode(e)
				tag = e.seTag[of kri.kit.bake.Tag]()
				return false	if not tag
				tVert.Value = tag.tVert
				tQuat.Value = tag.tQuat
				return true
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
		pm = geData[of kri.part.Manager]()
		ps = geData[of kri.part.beh.Standard]()
		return false	if not ps or not pm
		bgav = kri.part.beh.Gravity()
		pm.behos.Add(bgav)
		data = getVector()	# brownian, drag, damp
		ps.parForce.Value = Vector4(data)
		return true
