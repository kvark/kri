namespace kri.kit.hair

import OpenTK
import OpenTK.Graphics.OpenGL


#-----------------------------------#
#		Hair baking Tag				#
#-----------------------------------#

public class Tag( kri.ITag, kri.vb.ISource ):
	public final at_prev	= kri.Ant.Inst.slotParticles.getForced('prev')
	public final at_base	= kri.Ant.Inst.slotParticles.getForced('base')
	[Getter(Data)]
	private final aBase	as kri.vb.Attrib	= kri.vb.Attrib()
	public ready	as bool	= false

	public def constructor(size as uint):
		for i in range(2):
			kri.vb.enrich( aBase, 3, (at_prev,at_base)[i] )
		aBase.initAll(size)


#-----------------------------------#
#		Main Hair Behavior			#
#-----------------------------------#

public class Behavior( kri.part.beh.Basic ):
	# Y = cur seg ID, Z = 1 / segments
	public final pSegment	= kri.shade.par.Value[of Vector4]('fur_segment')
	# X = base thickness: [0,], Y = tip thickness: [0,], Z = shape: (-1,1)
	public final pThick		= kri.shade.par.Value[of Vector4]('fur_thick')
	# XYZ: tangent space direction, W: randomness
	public final pInit		= kri.shade.par.Value[of Vector4]('fur_init')
	# number of layers
	public final layers		as byte
	private final posId		as int
	# fun
	public def constructor(pc as kri.part.Context, segs as byte, length as single):
		super('./text/fur/main')
		kri.vb.enrich( self, 3, pc.at_pos, pc.at_speed )
		layers = segs
		posId = pc.at_pos
		kd = 1f / segs
		pSegment.Value	= Vector4( 0f, 0f, kd, 0f )
		pThick.Value	= Vector4( 0.1f, 0f, -0.6f, 0f )
		pInit.Value		= Vector4( 0f, 0f, length*kd, 0.5f*length*kd )
	public override def link(d as kri.shade.rep.Dict) as void:
		d.var(pSegment,pThick,pInit)

	# generate fur layers
	public def genLayers(man as kri.part.Manager, ent as kri.Entity) as (kri.part.Emitter):
		lar = array( kri.part.Emitter(man,"fur-${i}") for i in range(layers) )
		assert not ent.seTag[of Tag]()
		tag = Tag( man.total )
		ent.tags.Add(tag)
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
			pe.obj = ent
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
			pe.allocate()
		return lar


#-------------------------------------------#
#		Base attributes baking Render		#
#-------------------------------------------#

public class Bake( kri.rend.Basic ):
	public final va		= kri.vb.Array()
	public final vbo	= kri.vb.Attrib()
	public final sa		= kri.shade.Smart()
	public final tf		= kri.TransFeedback(1)
	private final pWid	= kri.shade.par.Value[of int]('width')
	private final pVert	= kri.shade.par.Texture('vert')
	private final pQuat	= kri.shade.par.Texture('quat')

	public def constructor(dict as kri.shade.rep.Dict):
		super(false)
		# init dictionary
		d = kri.shade.rep.Dict()
		d.var(pWid)
		d.unit(pVert,pQuat)
		# init shader
		sa.add('quat','./text/fur/base_v')
		sa.feedback(false, 'to_prev','to_base')
		sa.link( kri.Ant.Inst.slotAttributes, d, dict, kri.Ant.Inst.dict )
		# init fake vertex attrib for drawing
		vbo.Semant.Add( kri.vb.Info(
			size:1, slot:0, type:VertexAttribPointerType.UnsignedByte ))

	public override def process(con as kri.rend.Context) as void:
		va.bind()
		sa.use()
		for e in kri.Scene.Current.entities:
			tBake	= e.seTag[of kri.kit.bake.Tag]()
			tCur	= e.seTag[of Tag]()
			continue	if not tBake or not tCur
			total = tBake.wid * tBake.het
			vbo.initAll(total)
			pWid.Value	= tBake.wid
			pVert.Value	= tBake.tVert
			pQuat.Value	= tBake.tQuat
			tf.Bind( tCur.Data )
			sa.updatePar()
			using kri.Discarder(true), tf.catch():
				GL.DrawArrays( BeginMode.Points, 0, total )
			tCur.ready = true
