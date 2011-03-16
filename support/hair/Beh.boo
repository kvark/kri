namespace support.hair

import OpenTK

#-----------------------------------#
#		Main Hair Behavior			#
#-----------------------------------#

public class Behavior( kri.part.Behavior ):
	# Y = cur seg ID, Z = 1 / segments
	public final pSegment	= kri.shade.par.Value[of Vector4]('fur_segment')
	# X = 1 / avg_len
	public final pSystem	= kri.shade.par.Value[of Vector4]('fur_system')
	# number of layers
	public final layers		as byte
	private final posName	as string
	# fun
	public def constructor(pc as kri.part.Context, segs as byte):
		super('/part/beh/fur_main')
		enrich(3,'pos','speed')
		layers = segs
		kd = 1f / segs
		pSegment.Value	= Vector4( 0f, 0f, kd, 0f )
		pSystem.Value	= Vector4.Zero
	public override def link(d as kri.shade.rep.Dict) as void:
		d.var(pSegment,pSystem)

	# generate fur layers
	public def genLayers(em as kri.part.Emitter, init as Vector4) as (kri.part.Emitter):
		lar = List[of kri.part.Emitter]( kri.part.Emitter(em.owner,"${em.name}-${i}")\
			for i in range(layers) ).ToArray()
		assert not em.obj.seTag[of Tag]()
		tag = Tag( em.owner.Total )
		tag.param = init
		em.obj.tags.Add(tag)
		assert not 'ready'
		# localize id in a function
		def genFunc(id as int):
			return do(e as kri.Entity) as bool:
				pSegment.Value.Y = 1f*id
				return tag.stamp>0f
		/*ex0 = kri.part.ExtAttrib( dest:'prev' )
		ex1 = kri.part.ExtAttrib( dest:'base' )
		# external attribs setup
		for i in range(lar.Length):
			pe = lar[i]
			pe.obj = em.obj
			pe.mat = em.mat
			pe.onUpdate = genFunc(i)
			if i == 0:
				ex0.source = ex1.source = null
				ex0.vat = ex1.vat = tag
			else:
				assert not 'ready'
				ex1.source = posName
				#ex1.vat = lar[i-1]
				if i == 1:
					ex0.source = 'base'
					ex0.vat = tag
				else:
					ex0.source = posName
					#ex0.vat = lar[i-2]
			assert not 'ready'
			#pe.extList.AddRange((ex0,ex1))
		*/
		return lar
	
	# add children dependencies
	public static def prepareChildren(scene as kri.Scene, man as kri.part.Manager) as void:
		root as kri.vb.Attrib = null
		for pe in scene.particles:
			if pe.owner != man:
				continue
			assert pe.obj
			tag = pe.obj.seTag[of Tag]()
			assert tag
			if not root:
				root = tag.Data
			assert not 'ready'
			pe.exData.vbo.Add(root)
