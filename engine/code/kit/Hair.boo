namespace kri.kit.hair

import OpenTK
import OpenTK.Graphics.OpenGL


#-----------------------------------#
#		Hair baking Tag				#
#-----------------------------------#

public class Tag( kri.ITag, kri.vb.ISource ):
	public final va			= kri.vb.Array()
	public final at_prev	= kri.Ant.Inst.slotParticles.getForced('prev')
	public final at_base	= kri.Ant.Inst.slotParticles.getForced('base')
	[Getter(Data)]
	private final aBase	as kri.vb.Attrib	= kri.vb.Attrib()
	# XYZ: tangent space direction, W: randomness
	public param	= Vector4.UnitZ
	public ready	as bool	= false
	public final pixels	as uint

	public def constructor(size as uint):
		pixels = size
		va.bind()
		for i in range(2):
			kri.vb.enrich( aBase, 3, (at_prev,at_base)[i] )
		aBase.initAll(size)


#-----------------------------------#
#		Main Hair Behavior			#
#-----------------------------------#

public class Behavior( kri.part.beh.Basic ):
	# Y = cur seg ID, Z = 1 / segments
	public final pSegment	= kri.shade.par.Value[of Vector4]('fur_segment')
	# number of layers
	public final layers		as byte
	private final posId		as int
	# fun
	public def constructor(pc as kri.part.Context, segs as byte):
		super('/part/beh/fur_main')
		kri.vb.enrich( self, 3, pc.at_pos, pc.at_speed )
		layers = segs
		posId = pc.at_pos
		kd = 1f / segs
		pSegment.Value	= Vector4( 0f, 0f, kd, 0f )
	public override def link(d as kri.shade.rep.Dict) as void:
		d.var(pSegment)

	# generate fur layers
	public def genLayers(em as kri.part.Emitter, init as Vector4) as (kri.part.Emitter):
		lar = array( kri.part.Emitter(em.owner,"${em.name}-${i}") for i in range(layers) )
		assert not em.obj.seTag[of Tag]()
		tag = Tag( em.owner.total )
		tag.param = init
		em.obj.tags.Add(tag)
		# external attribs setup
		ex0 = kri.part.ExtAttrib( dest:tag.at_prev )
		ex1 = kri.part.ExtAttrib( dest:tag.at_base )
		# localize id in a function
		def genFunc(id as int):
			return do(e as kri.Entity) as bool:
				pSegment.Value.Y = 1f*id
				return tag.ready
		for i in range(lar.Length):
			pe = lar[i]
			pe.obj = em.obj
			pe.mat = em.mat
			pe.onUpdate = genFunc(i)
			if i == 0:
				ex0.source = ex1.source = -1
				ex0.vat = ex1.vat = tag
			else:
				ex1.source = posId
				ex1.vat = lar[i-1]
				if i == 1:
					ex0.source = tag.at_base
					ex0.vat = tag
				else:
					ex0.source = posId
					ex0.vat = lar[i-2]
			pe.extList.AddRange((ex0,ex1))
		return lar


#-------------------------------------------#
#		Base attributes baking Render		#
#-------------------------------------------#

public class Bake( kri.rend.Basic ):
	public final vbo	= kri.vb.Attrib()
	public final s_face	= kri.shade.Smart()
	public final s_vert	= kri.shade.Smart()
	public final tf		= kri.TransFeedback(1)
	private final pWid	= kri.shade.par.Value[of int]('width')
	private final pVert	= kri.shade.par.Texture('vert')
	private final pQuat	= kri.shade.par.Texture('quat')
	private final pInit	= kri.shade.par.Value[of Vector4]('fur_init')

	public def constructor():
		super(false)
		# init dictionary
		d = kri.shade.rep.Dict()
		d.var(pWid)
		d.var(pInit)
		d.unit(pVert,pQuat)
		# init shader
		com = kri.shade.Object('/part/fur/base/main_v')
		s_face.add('quat','/part/fur/base/face_v')
		s_vert.add('quat','/part/fur/base/vert_v')
		for sa in s_face,s_vert:
			sa.add(com)
			sa.feedback(false, 'to_prev','to_base')
			sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
		# init fake vertex attrib for drawing
		vbo.Semant.Add( kri.vb.Info(
			size:1, slot:0, type:VertexAttribPointerType.UnsignedByte ))

	public override def process(con as kri.rend.Context) as void:
		for e in kri.Scene.Current.entities:
			tCur	= e.seTag[of Tag]()
			continue	if not tCur
			pInit.Value = tCur.param
			tf.Bind( tCur.Data )
			tCur.va.bind()
			tBake	= e.seTag[of kri.kit.bake.Tag]()
			if tBake:	# emit from face
				vbo.initAll( tCur.pixels )
				pWid.Value	= tBake.wid
				pVert.Value	= tBake.tVert
				pQuat.Value	= tBake.tQuat
				s_face.use()
				using kri.Discarder(true), tf.catch():
					GL.DrawArrays( BeginMode.Points, 0, tCur.pixels )
			else:		# from vertices
				at = kri.Ant.Inst.attribs
				e.enable(true, (at.vertex, at.quat) )
				s_vert.use()
				assert tCur.pixels >= e.mesh.nVert
				#todo: what's left in the array?
				e.mesh.draw(tf)
			tCur.ready = true
