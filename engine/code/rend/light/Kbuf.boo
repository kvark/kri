namespace kri.rend.light.kbuf

import OpenTK.Graphics.OpenGL
import kri.shade


#---------	LIGHT INIT	--------#

public class Init( kri.rend.Basic ):
	public final layers	as byte
	public final buf	= kri.frame.Buffer()

	public def constructor(nlay as byte):
		maxSamples = 0
		GL.GetInteger( GetPName.MaxSamples, maxSamples )
		assert nlay <= maxSamples
		multi = TextureTarget.Texture2DMultisample
		layers = nlay
		buf.mask = 1
		buf.A[-0].Tex = kri.Texture(multi)
		buf.A[-2].Tex = kri.Texture(multi)
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		buf.A[-0].Tex.bind()
		kri.Texture.InitMulti( PixelInternalFormat.Rgba8,
			layers,true, far.Width, far.Height, 0 )
		buf.A[-2].Tex.bind()
		kri.Texture.InitMulti( PixelInternalFormat.Depth24Stencil8,
			layers,true, far.Width, far.Height, 0 )
		return true
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(false,0f,false)
		con.activeRead()	# bind as read FBO
		buf.activate()
		# depth copy
		GL.BlitFramebuffer(
			0,0, buf.Width, buf.Height,
			0,0, buf.Width, buf.Height,
			ClearBufferMask.DepthBufferBit,
			BlitFramebufferFilter.Nearest )
		# stencil
		using kri.Section( EnableCap.SampleMask ):
			GL.StencilMask(-1)
			for i in range(layers):
				GL.ClearStencil(i+1)
				GL.SampleMask(0,1<<i)
				GL.Clear( ClearBufferMask.StencilBufferBit )
			GL.SampleMask(0,-1)
		# color
		GL.ColorMask(true,true,true,true)
		GL.ClearColor(0f,0f,0f,0f)
		GL.Clear( ClearBufferMask.ColorBufferBit )



#---------	LIGHT PRE-PASS	--------#

public class Bake( kri.rend.Basic ):
	protected final sa		= Smart()
	protected final context	as kri.rend.light.Context
	protected final sphere	as kri.Mesh
	private final buf		as kri.frame.Buffer
	private final texDep	= par.Value[of kri.Texture]('depth')
	private final va		= kri.vb.Array()
	private final static 	geoQuality	= 1
	private final static	pif = PixelInternalFormat.Rgba

	public def constructor(init as Init, lc as kri.rend.light.Context):
		super(false)
		buf = init.buf
		context = lc
		# baking shader
		sa.add( '/light/kbuf/bake_v', '/light/kbuf/bake_f', '/lib/defer_f' )
		sa.add( *kri.Ant.Inst.libShaders )
		d = rep.Dict()
		d.unit(texDep)
		sa.link( kri.Ant.Inst.slotAttributes, d, lc.dict, kri.Ant.Inst.dict )
		# create geometry
		va.bind()	# the buffer objects are bound in creation
		sphere = kri.kit.gen.Sphere( geoQuality, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )

	public override def process(con as kri.rend.Context) as void:
		con.activate()
		texDep.Value = con.Depth
		buf.activate()
		con.SetDepth(0f,false)
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		using blender = kri.Blender(), kri.Section( EnableCap.StencilTest ):
			GL.StencilFunc( StencilFunction.Equal, 1,-1 )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Decr ) 
			blender.add()
			for l in kri.Scene.current.lights:
				continue	if l.fov != 0f
				kri.Ant.Inst.params.activate(l)
				sa.use()
				sphere.draw(1)
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )


#---------	LIGHT APPLICATION	--------#

public class Apply( kri.rend.tech.Meta ):
	private final buf	as kri.frame.Buffer
	private final pTex	= kri.shade.par.Texture('light')
	# init
	public def constructor(init as Init):
		super('lit.kbuf', false, null,
			'bump','emissive','diffuse','specular','glossiness')
		buf = init.buf
		pTex.Value = buf.A[0].Tex
		dict.unit( pTex )
		shade('/light/kbuf/apply')
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		drawScene()
