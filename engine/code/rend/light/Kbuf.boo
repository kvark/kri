namespace kri.rend.light.kbuf

import OpenTK.Graphics.OpenGL
import kri.shade


#---------	LIGHT INIT	--------#

public class Init( kri.rend.Basic ):
	public final layers	as byte
	public final buf	= kri.frame.Buffer(0)
	private final sa	= kri.shade.Smart()

	public def constructor(nlay as byte):
		maxSamples = 0
		GL.GetInteger( GetPName.MaxSamples, maxSamples )
		assert nlay <= maxSamples
		layers = nlay
		# init buffer
		multi = TextureTarget.Texture2DMultisample
		buf.mask = 3
		for i in (-2,0,1):
			buf.A[i].Tex = kri.Texture(multi)
		# init shader
		sa.add('/copy_v','/empty_f')
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	
	private def iniTex(i as int, pif as PixelInternalFormat) as void:
		buf.A[i].Tex.bind()
		kri.Texture.InitMulti( pif, layers, true, buf.Width, buf.Height, 0 )
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		iniTex(-2,	PixelInternalFormat.Depth24Stencil8 )
		#iniTex(0,	PixelInternalFormat.R11fG11fB10f )
		iniTex(0,	PixelInternalFormat.Rgb16f )
		iniTex(1,	PixelInternalFormat.Rgb10A2 )
		return true
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(false,0f,true)
		buf.activate(0)		# bind as draw
		con.activeRead()	# bind as read
		# depth copy
		buf.blit( ClearBufferMask.DepthBufferBit )
		# stencil init
		GL.StencilMask(-1)
		if 'RectangleFill':
			assert layers > 0
			con.DepTest = false
			con.ClearStencil(1)
			sa.use()
			# todo: optimize to use less passes
			using kri.Section( EnableCap.SampleMask ), kri.Section( EnableCap.StencilTest ):
				GL.StencilFunc( StencilFunction.Always, 0,0 )
				GL.StencilOp( StencilOp.Incr, StencilOp.Incr, StencilOp.Incr )
				for i in range(1,layers):
					GL.SampleMask( 0, -1<<i )
					kri.Ant.Inst.emitQuad()
		else:
			using kri.Section( EnableCap.SampleMask ):
				for i in range(layers):
					GL.SampleMask(0,1<<i)
					con.ClearStencil(i+1)
		# color clear
		buf.activate(3)
		GL.ColorMask(true,true,true,true)
		con.ClearColor()


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
		sa.fragout('rez_dir','rez_color')
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
		buf.activate(3)
		con.SetDepth(0f,false)
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		sa.use()
		using blender = kri.Blender(), kri.Section( EnableCap.StencilTest ):
			GL.StencilFunc( StencilFunction.Equal, 1,-1 )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Decr )
			blender.add()
			for l in kri.Scene.current.lights:
				continue	if l.fov != 0f
				kri.Ant.Inst.params.activate(l)
				sa.updatePar()
				sphere.draw(1)
				break	# !!!!!!!
		GL.CullFace( CullFaceMode.Back )
		GL.DepthFunc( DepthFunction.Lequal )


#---------	LIGHT APPLICATION	--------#

public class Apply( kri.rend.tech.Meta ):
	private final buf	as kri.frame.Buffer
	private final pDir	= kri.shade.par.Texture('dir')
	private final pCol	= kri.shade.par.Texture('color')
	# init
	public def constructor(init as Init):
		super('lit.kbuf', false, null,
			'bump','emissive','diffuse','specular','glossiness')
		buf = init.buf
		pDir.Value = buf.A[0].Tex
		pCol.Value = buf.A[1].Tex
		dict.unit( pDir, pCol )
		shade('/light/kbuf/apply')
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		con.ClearColor()
		drawScene()
