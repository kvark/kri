namespace kri.rend.light.g

import System
import OpenTK.Graphics.OpenGL
import kri.rend


#---------	RENDER TO G-BUFFER	--------#

public class Fill( tech.Meta ):
	public final buf		= kri.frame.Buffer()
	public GBuf as kri.Texture:
		get: return buf.A[0].Tex
	# init
	public def constructor():
		super('g.make', ('c_diffuse','c_specular','c_normal'), *kri.load.Meta.LightSet)
		shade(('/g/make_v','/g/make_f','/light/common_f'))
		t = kri.Texture( TextureTarget.Texture2DArray )
		buf.A[0].layer(t,0) # diffuse
		buf.A[1].layer(t,1) # specular
		buf.A[2].layer(t,2)	# world space normal
		buf.mask = 0x7
	# resize
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		buf.A[0].Tex.bind()
		fm = kri.Texture.AskFormat( kri.Texture.Class.Color, 8 )
		fm = PixelInternalFormat.Rgb10A2
		kri.Texture.InitArray(fm, far.Width, far.Height, 3)
		kri.Texture.Filter(false,false)
		return true
	# work	
	public override def process(con as Context) as void:
		con.needDepth(false)
		buf.A[-1].Tex = con.Depth
		buf.activate()
		con.SetDepth(0f, false)
		con.ClearColor()
		drawScene()


#---------	RENDER APPLY G-BUFFER	--------#

public class Apply( Basic ):
	protected final s0	= kri.shade.Smart()
	protected final sa	= kri.shade.Smart()
	protected final va	= kri.vb.Array()
	private final texDep	= kri.shade.par.Value[of kri.Texture]('depth')
	private final gbuf		= kri.shade.par.Value[of kri.Texture]('gbuf')
	private final texLit	= kri.shade.par.Value[of kri.Texture]('light')
	private final context	as light.Context
	private final sphere	as kri.Mesh
	# init
	public def constructor(gt as kri.Texture, lc as light.Context, qord as byte):
		super(false)
		context = lc
		gbuf.Value = gt
		# fill shader
		s0.add( 'copy_v', '/g/init_f' )
		s0.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
		# light shader
		d = kri.shade.rep.Dict()
		d.unit(texDep,gbuf,texLit)
		sa.add( '/g/apply_v', '/g/apply_f', 'quat','tool' )
		sa.add( '/mod/lambert_f', '/mod/phong_f' )
		sa.link( kri.Ant.Inst.slotAttributes, d, lc.dict, kri.Ant.Inst.dict )
		# bake sphere attribs
		va.bind()	# the buffer objects are bound in creation
		sphere = kri.kit.gen.sphere( qord, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )
	# shadow 
	private def bindShadow(t as kri.Texture) as void:
		if t:
			texLit.Value = t
			t.bind()
			kri.Texture.Filter(false,false)
			kri.Texture.Shadow(false)
		else:
			texLit.Value = context.defShadow
	# work
	public override def process(con as Context) as void:
		con.activate()
		texDep.Value = con.Depth
		texDep.Value.bind()
		kri.Texture.Filter(false,false)
		kri.Texture.Shadow(false)
		# initial fill
		s0.use()
		kri.Ant.Inst.emitQuad()
		# enable depth check
		con.activate(true,0f,false)
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		# add lights
		using blend = kri.Blender():
			blend.add()
			for l in kri.Scene.current.lights:
				bindShadow( l.depth )
				kri.Ant.Inst.params.activate(l)
				sa.use()
				sphere.draw()
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )
