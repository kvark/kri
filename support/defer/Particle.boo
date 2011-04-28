namespace support.defer

public class Particle(ApplyBase):
	private final pHalo		= kri.shade.par.Value[of OpenTK.Vector4]('halo_data')
	private final light		= kri.Light( energy:1f, quad1:0f, quad2:0f )
	# init
	public def constructor(pc as kri.part.Context, con as Context, qord as byte):
		super(qord)
		con.dict.var(pHalo)
		bu.shader.add('/part/draw/light_v')
		relink(con)
	# work
	private override def onDraw() as void:
		scene = kri.Scene.Current
		if not scene:	return
		# draw particles
		for pe in scene.particles:
			#todo: add light particle meta
			if not (pe.mat and pe.Ready):
				continue
			halo = pe.mat.Meta['halo'] as kri.meta.Halo
			if not halo:
				continue
			pHalo.Value = halo.Data
			light.setLimit( pHalo.Value.X )
			d = kri.vb.Dict( sphere.mesh, pe.mesh )
			for s in ('sys','pos'):
				en = kri.vb.Entry(pe,s)
				en.divisor = 1
				d['ghost_'+s] = en
			kri.Ant.Inst.params.activate(light)
			sphere.mesh.render( pe.owner.va, bu, d, 1, null )
