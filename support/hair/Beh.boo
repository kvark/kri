namespace support.hair

import OpenTK

#-----------------------------------#
#		Main Hair Behavior			#
#-----------------------------------#

public class Behavior( kri.part.Behavior ):
	# Y = cur seg ID, Z = 1 / segments
	public final pSegment	= kri.shade.par.Value[of Vector4]('fur_segment')
	# number of layers
	public final layers		as byte
	private final posId		as int
	# fun
	public def constructor(pc as kri.part.Context, segs as byte):
		super('/part/beh/fur_main')
		kri.Help.enrich( self, 3, pc.at_pos, pc.at_speed )
		layers = segs
		posId = pc.at_pos
		kd = 1f / segs
		pSegment.Value	= Vector4( 0f, 0f, kd, 0f )
	public override def link(d as kri.shade.rep.Dict) as void:
		d.var(pSegment)

	# generate fur layers
	public def genLayers(em as kri.part.Emitter, init as Vector4) as (kri.part.Emitter):
		lar = List[of kri.part.Emitter]( kri.part.Emitter(em.owner,"${em.name}-${i}")\
			for i in range(layers) ).ToArray()
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
				return tag.stamp>0f
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
