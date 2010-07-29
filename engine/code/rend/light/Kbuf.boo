namespace kri.rend.light.kbuf

import OpenTK.Graphics.OpenGL
import kri.shade


#---------	LIGHT INIT	--------#

public class Init( kri.rend.Basic ):
	public final buf	as kri.frame.Buffer
	private final sa	= kri.shade.Smart()

	public def constructor(nlay as byte):
		maxSamples = 0
		GL.GetInteger( GetPName.MaxSamples, maxSamples )
		assert nlay <= maxSamples
		# init buffer
		buf = kri.frame.Buffer(nlay, TextureTarget.Texture2DMultisample )
		buf.mask = 3
		buf.emit(-2,	PixelInternalFormat.Depth24Stencil8 )
		buf.emit(0,		PixelInternalFormat.Rgb16f )	# R11fG11fB10f
		buf.emit(1,		PixelInternalFormat.Rgb10A2 )
		# init shader
		sa.add('/copy_v','/white_f') # temp
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		return true
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(false,0f,true)
		GL.Disable( EnableCap.Multisample )
		# depth copy
		buf.activate(0)		# bind as draw
		con.activeRead()	# bind as read
		buf.blit( ClearBufferMask.DepthBufferBit )
		# stencil init
		GL.StencilMask(-1)
		if 'RectangleFill':
			assert buf.Samples > 0
			con.DepTest = false
			con.ClearStencil(1)
			sa.use()
			#sb = -1; GL.GetInteger( GetPName.SampleBuffers, sb )
			#sm = -1; GL.GetInteger( GetPName.Samples, sm )
			# todo: optimize to use less passes
			using kri.Section( EnableCap.SampleMask ), kri.Section( EnableCap.StencilTest ):
				GL.StencilFunc( StencilFunction.Always, 0,0 )
				GL.StencilOp( StencilOp.Incr, StencilOp.Incr, StencilOp.Incr )
				for i in range(1, buf.Samples ):
					GL.SampleMask( 0, -1<<i )
					kri.Ant.Inst.emitQuad()
		else:
			using kri.Section( EnableCap.SampleMask ):
				for i in range( buf.Samples ):
					GL.SampleMask(0,1<<i)
					con.ClearStencil(i+1)
		GL.SampleMask(0,-1)
		# color clear
		buf.activate(3)
		GL.ColorMask(true,true,true,true)
		con.ClearColor()
		return
		# debug!
		buf.activate(2)
		sa.use()
		using kri.Section( EnableCap.StencilTest ):
			GL.StencilFunc( StencilFunction.Equal, 1,-1 )	#change this to see the stencil layer
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Keep )
			kri.Ant.Inst.emitQuad()


#---------	LIGHT PRE-PASS	--------#

public class Bake( kri.rend.Basic ):
	protected final sa		= Smart()
	protected final sb		= Smart()
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
		# create white shader
		sb.add('/light/kbuf/bake_v','/empty_f')
		sb.add( *kri.Ant.Inst.libShaders )
		sb.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	private def drawLights(mask as byte, sx as Smart) as void:
		buf.activate(mask)
		sx.use()
		for l in kri.Scene.current.lights:
			continue	if l.fov != 0f
			kri.Ant.Inst.params.activate(l)
			sx.updatePar()
			sphere.draw(1)
			#break	# !debug!

	public override def process(con as kri.rend.Context) as void:
		#return	# !debug!
		con.activate()
		texDep.Value = con.Depth
		con.SetDepth(0f,false)
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
		GL.Disable( EnableCap.Multisample )
		#todo: use stencil for front faces
		using kri.Section( EnableCap.StencilTest ):
			# write color values
			GL.StencilFunc( StencilFunction.Equal, 1,-1 )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Keep )
			drawLights(3,sa)
			# shift stencil route
			GL.StencilFunc( StencilFunction.Always, 0,0 )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Decr )
			drawLights(0,sb)
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
