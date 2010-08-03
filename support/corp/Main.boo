namespace support.corp

import System
import OpenTK
import OpenTK.Graphics.OpenGL


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
		return support.bake.Tag(wid,het,b_pos,b_rot,filt)


public class Extra( kri.IExtension ):
	public final pcon	= kri.part.Context()
	public bake			= SetBake( pixels:1<<16, ratio:1f, b_pos:16, b_rot:8, filt:false )
	public bLoop		= false
	
	public def attach(nt as kri.load.Native) as void:	#imp: kri.IExtension
		# particles
		nt.readers['part']		= p_part
		nt.readers['p_dist']	= pp_dist
		nt.readers['p_life']	= pp_life
		nt.readers['p_hair']	= pp_hair
		nt.readers['p_vel']		= pp_vel
		nt.readers['p_rot']		= pp_rot
		nt.readers['p_phys']	= pp_phys

	public def finish(pe as kri.part.Emitter) as void:
		pm = pe.owner
		if not pm.Ready:
			ps = pm.seBeh[of beh.Standard]()
			ph = pm.seBeh[of support.hair.Behavior]()
			if ps:
				pm.behos.Add( beh.Sys(pcon) )
				pm.makeStandard(pcon)
				born = (pcon.sh_born_time, pcon.sh_born_loop)[ bLoop ]
				pm.col_update.extra.Add(born)
			elif ph: pm.makeHair(pcon)
			else: return
			pm.init(pcon)
		pe.allocate()
	
	private def upNode(e as kri.Entity):
		assert e
		kri.Ant.Inst.params.modelView.activate( e.node )
		return true


	#---	Parse emitter object	---#
	public def p_part(r as kri.load.Reader) as bool:
		pm = kri.part.Manager( r.bin.ReadUInt32() )
		r.puData(pm)
		# create emitter
		pe = kri.part.Emitter( pm, r.getString() )
		r.puData(pe)
		pe.obj = r.geData[of kri.Entity]()
		r.at.scene.particles.Add(pe)
		# link to material
		pe.mat = r.at.mats[ r.getString() ]
		pe.mat = kri.Ant.Inst.loaders.materials.con.mDef	if not pe.mat
		# post-process
		r.addPostProcess() do(n as kri.Node):
			finish(pe)
		return true


	#---	Parse distribution		---#
	public def pp_dist(r as kri.load.Reader) as bool:
		source = r.getString()
		r.getString()	# type
		r.getReal()		# jitter factor
		ent = r.geData[of kri.Entity]()
		pe = r.geData[of kri.part.Emitter]()
		return false	if not pe
		pm = pe.owner
		
		ph = pm.seBeh[of support.hair.Behavior]()
		if not ent.seTag[of support.bake.Tag]():
			st = bake
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
				tag = e.seTag[of support.bake.Tag]()
				return false	if not tag
				tVert.Value = tag.Vert
				tQuat.Value = tag.Quat
				return true
			sh = pcon.sh_surf_face
		else: assert not 'supported :('
		pm.col_update.extra.Add(sh)
		return true


	#---	Parse life data	(emitter)	---#
	public def pp_life(r as kri.load.Reader) as bool:
		pm = r.geData[of kri.part.Manager]()
		return false	if not pm
		bh = beh.Standard(pcon)
		pm.behos.Add( bh )
		data = r.getVec4()	# start,end, life time, random
		bh.parLife.Value = Vector4( data.Z, data.W, data.Y-data.X, 1f )
		return true
	
	#---	Parse hair dynamics data	---#
	public def pp_hair(r as kri.load.Reader) as bool:
		pm = r.geData[of kri.part.Manager]()
		return false	if not pm
		segs = r.getByte()
		pm.behos.Add( support.hair.Behavior(pcon,segs) )
		dyn = r.getVector()	# stiffness, mass, bending
		dyn.Z *= 20f
		damp = r.getVec2()	# spring, air
		damp.X *= 1.5f
		pm.behos.Insert(0, beh.Damp( damp.X ))
		// standard behavior appears here
		pm.behos.Add( beh.Bend( dyn.Z ))
		pm.behos.Add( beh.Norm() )
		return true
	
	#---	Parse velocity setup		---#
	public def pp_vel(r as kri.load.Reader) as bool:
		pe = r.geData[of kri.part.Emitter]()
		return false	if not pe or not pe.owner
		objFactor	= r.getVector()	# object-aligned factor
		tanFactor	= r.getVector()	# normal, tangent, tan-phase
		add			= r.getVec2()	# object speed, random
		tan	= Vector3( tanFactor.Y, 0f, tanFactor.X )
		# get behavior
		ps = pe.owner.seBeh[of beh.Standard]()
		ph = pe.owner.seBeh[of support.hair.Behavior]()
		if ps:		# standard
			ps.parVelObj.Value = Vector4( objFactor, add.Y )
			ps.parVelTan.Value = Vector4( tan, tanFactor.Z )
			ps.parVelKeep.Value = Vector4.Zero
		elif ph:	# hair
			magic = 5f / ph.layers	# todo: find out Blender scale source
			lays = ph.genLayers( pe, magic * Vector4(tan,add.Y) )
			r.at.scene.particles.Remove(pe)
			r.at.scene.particles.AddRange(lays)
		else: return false
		return true
	
	public def pp_rot(r as kri.load.Reader) as bool:
		mode = r.getString()
		factor = r.getReal()
		if mode == 'SPIN':
			pm = r.geData[of kri.part.Manager]()
			return false	if not pm
			pm.behos.Add( beh.Rotate(factor,pcon) )
		return true
	
	public def pp_phys(r as kri.load.Reader) as bool:
		pm = r.geData[of kri.part.Manager]()
		return false	if not pm
		pg = r.at.scene.pGravity
		if pg:
			bgav = beh.Gravity(pg)
			if pm.seBeh[of support.hair.Behavior]():
				pm.behos.Insert(0,bgav)
			else: pm.behos.Add(bgav)
		biz = beh.Physics()
		biz.pSize.Value = Vector4( r.getVec2() )
		# forces: brownian, drag, damp
		biz.pForce.Value = Vector4( r.getVector() )
		pm.behos.Add(biz)
		return true
	
	public def ppr_inst(r as kri.load.Reader) as bool:
		pe = r.geData[of kri.part.Emitter]()
		return false	if not pe or not pe.mat or\
			pe.mat == kri.Ant.Inst.loaders.materials.con.mDef
		inst = kri.meta.Inst( Name:'inst' )
		pe.mat.metaList.Add(inst)
		r.addResolve() do(n as kri.Node):
			inst.ent = r.at.scene.entities.Find({e| return e.node==n })
		return true
