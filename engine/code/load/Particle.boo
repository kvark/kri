namespace kri.load

import System
import OpenTK

public struct SetBake:
	public pixels	as uint
	public ratio	as single
	public b_pos	as byte
	public b_rot	as byte
	public filt		as bool
	public def tag() as kri.ITag:
		assert ratio > 0f
		side = Math.Sqrt(pixels / ratio)
		wid,het = cast(int,side*ratio),cast(int,side)
		return kri.kit.bake.Tag(wid,het,b_pos,b_rot,filt)

public partial class Settings:
	public bake		= SetBake( pixels:1<<16, ratio:1f, b_pos:16, b_rot:8, filt:false )
	public bLoop	= false



public partial class Native:
	public final pcon =	kri.part.Context()

	public def finishParticles() as void:
		for pe in at.scene.particles:
			pm = pe.owner
			if not pm.Ready:
				ps = pm.seBeh[of kri.part.beh.Standard]()
				ph = pm.seBeh[of kri.kit.hair.Behavior]()
				if ps:
					pm.behos.Add( kri.part.beh.Sys(pcon) )
					pm.makeStandard(pcon)
					born = (pcon.sh_born_time, pcon.sh_born_loop)[ sets.bLoop ]
					pm.col_update.extra.Add(born)
				elif ph: pm.makeHair(pcon)
				else: continue
				pm.init(pcon)
			pe.allocate()


	#---	Parse emitter object	---#
	public def p_part() as bool:
		pm = kri.part.Manager( br.ReadUInt32() )
		puData(pm)
		# create emitter
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
		source = getString()
		getString()		# type
		br.ReadSingle()	# jitter factor
		ent = geData[of kri.Entity]()
		pe = geData[of kri.part.Emitter]()
		return false	if not pe
		pm = pe.owner
		
		ph = pm.seBeh[of kri.kit.hair.Behavior]()
		if not ent.seTag[of kri.kit.bake.Tag]():
			st = sets.bake
			st.pixels = pm.total	if ph
			ent.tags.Add( st.tag() )
		if ph:
			assert source in ('VERT','FACE')
			return true

		sh as kri.shade.Object	= null
		if source == '':
			sh = pcon.sh_surf_node
			pe.onUpdate = upNode
		elif source == 'VERT':
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
			pe.onUpdate = def(e as kri.Entity):
				upNode(e)
				tag = e.seTag[of kri.kit.bake.Tag]()
				return false	if not tag
				tVert.Value = tag.Vert
				tQuat.Value = tag.Quat
				return true
			sh = pcon.sh_surf_face
		else: assert not 'supported :('
		pm.col_update.extra.Add(sh)
		return true


	#---	Parse life data	(emitter)	---#
	public def pp_life() as bool:
		pm = geData[of kri.part.Manager]()
		return false	if not pm
		beh = kri.part.beh.Standard(pcon)
		pm.behos.Add( beh )
		data = getVec4()	# start,end, life time, random
		beh.parLife.Value = Vector4( data.Z, data.W, data.Y-data.X, 1f )
		return true
	
	#---	Parse hair dynamics data	---#
	public def pp_hair() as bool:
		pm = geData[of kri.part.Manager]()
		return false	if not pm
		segs = br.ReadByte()
		pm.behos.Add( kri.kit.hair.Behavior(pcon,segs) )
		dyn = getVector()	# stiffness, mass, bending
		dyn.Z *= 20f
		damp = getVec2()	# spring, air
		damp.X *= 1.5f
		pm.behos.Insert(0, kri.part.beh.Damp( damp.X ))
		// standard behavior appears here
		pm.behos.Add( kri.part.beh.Bend( dyn.Z ))
		pm.behos.Add( kri.part.beh.Norm() )
		return true
	
	#---	Parse velocity setup		---#
	public def pp_vel() as bool:
		pe = geData[of kri.part.Emitter]()
		return false	if not pe or not pe.owner
		objFactor	= getVector()	# object-aligned factor
		tanFactor	= getVector()	# normal, tangent, tan-phase
		add			= getVec2()		# object speed, random
		tan	= Vector3( tanFactor.Y, 0f, tanFactor.X )
		# get behavior
		ps = pe.owner.seBeh[of kri.part.beh.Standard]()
		ph = pe.owner.seBeh[of kri.kit.hair.Behavior]()
		if ps:		# standard
			ps.parVelObj.Value = Vector4( objFactor, add.Y )
			ps.parVelTan.Value = Vector4( tan, tanFactor.Z )
			ps.parVelKeep.Value = Vector4.Zero
		elif ph:	# hair
			magic = 5f / ph.layers	# todo: find out Blender scale source
			lays = ph.genLayers( pe, magic * Vector4(tan,add.Y) )
			at.scene.particles.Remove(pe)
			at.scene.particles.AddRange(lays)
		else: return false
		return true
	
	public def pp_rot() as bool:
		mode = getString()
		factor = getReal()
		if mode == 'SPIN':
			pm = geData[of kri.part.Manager]()
			return false	if not pm
			pm.behos.Add( kri.part.beh.Rotate(factor,pcon) )
		return true
	
	public def pp_phys() as bool:
		pm = geData[of kri.part.Manager]()
		return false	if not pm
		pg = at.scene.pGravity
		if pg:
			bgav = kri.part.beh.Gravity(pg)
			if pm.seBeh[of kri.kit.hair.Behavior]():
				pm.behos.Insert(0,bgav)
			else: pm.behos.Add(bgav)
		biz = kri.part.beh.Physics()
		biz.pSize.Value = Vector4( getVec2() )
		# forces: brownian, drag, damp
		biz.pForce.Value = Vector4( getVector() )
		pm.behos.Add(biz)
		return true
	
	public def ppr_inst() as bool:
		pe = geData[of kri.part.Emitter]()
		return false	if not pe or not pe.mat or pe.mat == con.mDef
		inst = kri.meta.Inst( Name:'inst' )
		pe.mat.metaList.Add(inst)
		addResolve() do(n as kri.Node):
			inst.ent = at.scene.entities.Find({e| return e.node==n })
		return true
