namespace kri.kit.skin

import System


public class Tag( kri.ITag ):
	public skel		as kri.Skeleton	= null
	private state	as int	 = 0
	public Sync as bool:
		get: return state == skel.State
		set: state = skel.State - (0 if value else 1)


public def prepare(e as kri.Entity, s as kri.Skeleton) as bool:
	a = kri.Ant.Inst.attribs
	cond = e and s and not e.seTag[of Tag]() and e.mesh.find(a.skin)
	return false	if not cond
	for at in (a.vertex, a.quat):
		continue	if e.find(at)
		v = e.mesh.find(at)
		return false	if not v
		ai = v.semantics[0]
		v2 = kri.vb.Attrib()
		v2.semantics.Add(ai)
		v2.init( e.mesh.nVert * ai.fullSize() )
		e.vbo.Add(v2)
	e.tags.Add( Tag(skel:s) )
	return true


public def getAnim(e as kri.Entity, str as string) as kri.ani.data.Anim:
	return e.seTag[of Tag]().skel.play(str)


#---------	RENDER SKELETON SYNC		--------#

public class Update( kri.rend.Basic ):
	private final tf	= kri.TransFeedback()
	private final sa	= kri.shade.Smart()
	private final va	= kri.vb.Array()
	private final par	= array[of kri.lib.par.Spatial](80)
	public final at_mod	= (kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat)
	public final at_all	= at_mod + (kri.Ant.Inst.attribs.skin,)

	public def constructor():
		super(false)
		dict = kri.shade.rep.Dict()
		for i in range(par.Length):
			name = "bone[${i}]"
			par[i] = kri.lib.par.Spatial(dict,name)
		# prepare shader
		sa.add( '/skin_v', 'quat' )
		tf.setup(sa, true, 'to_vertex', 'to_quat')
		sa.link(kri.Ant.Inst.slotAttributes, dict)
		# finish
		spat = kri.Spatial.Identity
		par[0].activate(spat)

	public override def process(con as kri.rend.Context) as void:
		va.bind()
		using kri.Discarder():
			for e in kri.Scene.Current.entities:
				tag = e.seTag[of Tag]()
				continue	if not e.visible or not tag or tag.Sync
				vos = Array.ConvertAll(at_mod) do(a as int):
					return e.find(a)
				continue	if null in vos
				tf.bind( *vos )
				for at in sa.gatherAttribs( kri.Ant.Inst.slotAttributes ):
					rez = e.mesh.bind(at)
					assert rez
				# run the transform
				spa as kri.Spatial
				for i in range(tag.skel.bones.Length):
					s0 = e.node.Local	# model->
					tag.skel.bones[i].genTransPose(s0,spa)	# ->pose
					s1 = tag.skel.bones[i].World
					s0.combine(spa,s1)	# ->world
					s1 = e.node.World
					s1.inverse()
					spa.combine(s0,s1)	# ->model
					par[i+1].activate(spa)
				sa.use()
				e.mesh.draw(tf)
				tag.Sync = true
