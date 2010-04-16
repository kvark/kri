namespace kri.rend.part

import OpenTK.Graphics.OpenGL


public class Light( kri.rend.Basic ):
	private final sa	= kri.shade.Smart()
	private final va	= kri.vb.Array()
	private final texDep	= kri.shade.par.Value[of kri.Texture]('depth')
	private final gbuf		= kri.shade.par.Value[of kri.Texture]('gbuf')
	private final texPart	= kri.shade.par.Value[of kri.Texture]('part')
	private final light		= kri.Light()
	private final sphere	as kri.Mesh
	private final dict		= kri.shade.rep.Dict()
	# init
	public def constructor(gt as kri.Texture, qord as byte):
		super(false)
		gbuf.Value = gt
		texPart.Value = kri.Texture( TextureTarget.TextureBuffer )
		dict.unit(texDep, gbuf, texPart)
		# light shader
		sa.add( '/part/draw_light_v', '/g/apply_f', 'quat','tool','defer' )
		sa.add( '/mod/lambert_f', '/mod/phong_f' )
		sa.link( kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
		# bake sphere attribs
		va.bind()	# the buffer objects are bound in creation
		sphere = kri.kit.gen.sphere( qord, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )
	# work
	public override def process(con as kri.rend.Context) as void:
		con.needDepth(false)
		texDep.Value = con.Depth
		# enable depth check
		con.activate( true,0f,false )
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		kri.Ant.Inst.params.activate(light)
		# draw instanced
		using blend = kri.Blender():
			blend.add()
			for pe in kri.Scene.Current.particles:
				texPart.Value.bind()
				kri.Texture.Init( SizedInternalFormat.Rgba32f, pe.data )
				sa.use()
				sphere.draw( pe.man.total )
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )
