namespace kri.rend.part

import OpenTK.Graphics.OpenGL

public class Light( kri.rend.defer.ApplyBase ):
	private final texPart	= kri.shade.par.Value[of kri.Texture]('part')
	private final pHalo		= kri.shade.par.Value[of OpenTK.Vector4]('halo_data')
	private final light		= kri.Light( energy:1f, quad1:0f, quad2:0f )
	# init
	public def constructor(con as kri.rend.defer.Context, qord as byte):
		super(qord)
		texPart.Value = kri.Texture( TextureTarget.TextureBuffer )
		dict.var(pHalo)
		dict.unit(texPart)
		sa.add('/part/draw_light_v')
		relink(con)
	# work
	private override def onDraw() as void:
		for pe in kri.Scene.Current.particles:
			pHalo.Value = pe.halo.Data
			light.setLimit( pHalo.Value.X )
			texPart.Value.bind()
			kri.Texture.Init( SizedInternalFormat.Rgba32f, pe.data )
			kri.Ant.Inst.params.activate(light)
			sa.use()
			sphere.draw( pe.man.total )
