namespace support.defer

import System.Collections.Generic


public class Particle(ApplyBase):
	private final pHalo		= kri.shade.par.Value[of OpenTK.Vector4]('halo_data')
	private final light		= kri.Light( energy:1f, quad1:0f, quad2:0f )
	private final trans		= Dictionary[of string,string]()
	# init
	public def constructor(pc as kri.part.Context, con as Context, qord as byte):
		super(qord)
		# attributes
		for s in ('sys','pos'):
			trans[s] = '@'+s
		# program link
		dict.var(pHalo)
		bu.shader.add('/part/draw/light_v')
		relink(con)
	# work
	private override def onDraw() as void:
		assert not 'supported'	#
		#for at in trans.Values:
		#	GL.Arb.VertexAttribDivisor(at,1)
		# draw particles
		for pe in kri.Scene.Current.particles:
			#todo: add light particle meta
			continue	if not pe.mat
			halo = pe.mat.Meta['halo'] as kri.meta.Halo
			continue	if not halo
			pHalo.Value = halo.Data
			light.setLimit( pHalo.Value.X )
			#pe.data.attribTrans(trans)	#?
			kri.Ant.Inst.params.activate(light)
			bu.activate()
			assert not 'supported' # trans attribs
			#sphere.draw( pe.owner.total )
