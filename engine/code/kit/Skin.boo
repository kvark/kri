namespace kri.kit.skin

import System


public class Tag( kri.ITag ):
	public skel		as kri.Skeleton	= null
	private state	as int	 = 0
	public Sync as bool:
		get: return state == skel.State
		set: state = skel.State - (0 if value else 1)
	
	public static def prepare(e as kri.Entity, s as kri.Skeleton) as bool:
		a = kri.Ant.Inst.attribs
		cond = e and s and not e.seTag[of Tag]() and e.mesh.find(a.skin)
		return false	if not cond
		for at in (a.vertex, a.quat):
			continue	if e.store.find(at)
			v = e.mesh.find(at)
			return false	if not v
			ai = v.Semant[0]
			v2 = kri.vb.Attrib()
			v2.Semant.Add(ai)
			v2.init( e.mesh.nVert * ai.fullSize() )
			e.store.vbo.Add(v2)
		e.tags.Add( Tag(skel:s) )
		return true
	
	public static def getAnim(e as kri.Entity, str as string) as kri.ani.data.Anim:
		return e.seTag[of Tag]().skel.play(str)



#---------	RENDER SKELETON SYNC		--------#

public class Update( kri.rend.tech.Basic ):
	private final tf	= kri.TransFeedback(1)
	private final sa	= kri.shade.Smart()
	private final par	= array( kri.lib.par.spa.Shared("bone[${i}]") for i in range(80) )
	public final at_mod	= (kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat)
	public final at_all	as (int)

	public def constructor(dq as bool):
		super('skin')
		dict = kri.shade.rep.Dict()
		for p as kri.meta.IBase in par:
			p.link(dict)
		# prepare shader
		sa.add( '/lib/quat_v', '/skin/main_v' )
		sa.add( ('/skin/simple_v','/skin/dual_v')[dq] )
		#old: sa.add( '/skin/zcull_v', '/lib/tool_v', '/empty_f' )
		sa.add( '/skin/empty_v' )
		sa.feedback(true, 'to_vertex', 'to_quat')
		sl = kri.Ant.Inst.slotAttributes
		sa.link(sl, dict, kri.Ant.Inst.dict)
		at_all = array( sa.gatherAttribs(sl,false) )
		# finish
		spat = kri.Spatial.Identity
		par[0].activate(spat)

	public override def process(con as kri.rend.Context) as void:
		sa.use()
		using kri.Discarder(true):
			for e in kri.Scene.Current.entities:
				kri.Ant.Inst.params.modelView.activate( e.node )
				tag = e.seTag[of Tag]()
				continue	if not e.visible or not tag or tag.Sync\
					or not attribs(false, e, *at_all)
				vos = Array.ConvertAll(at_mod) do(a as int):
					return e.store.find(a)
				continue	if null in vos
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
				kri.shade.Smart.UpdatePar()
				e.mesh.draw(tf)
				tag.Sync = true
