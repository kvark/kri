namespace support.light.kbuf

import OpenTK.Graphics.OpenGL
import kri.shade
import kri.buf


#---------	LIGHT INIT	--------#

public class Init( kri.rend.Basic ):
	public final buf	as Target
	private final sa	= kri.shade.Smart()

	public def constructor(nlay as byte):
		# init buffer
		tt = TextureTarget.Texture2DMultisample
		buf = Target( mask:3 )
		buf.at.stencil	= Texture.Stencil(nlay)
		buf.at.color[0]	= Texture( target:tt, samples:nlay,
			intFormat:PixelInternalFormat.Rgb16f )	# R11fG11fB10f
		buf.at.color[1]	= Texture( target:tt, samples:nlay,
			intFormat:PixelInternalFormat.Rgb10A2 )
		# init shader
		sa.add('/copy_v','/white_f') # temp
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	
	public override def setup(pl as kri.buf.Plane) as bool:
		buf.resize( pl.wid, pl.het )
		return true
	
	public override def process(con as kri.rend.Context) as void:
		con.activate(false,0f,true)
		con.Multisample = false
		# depth copy
		buf.mask = 0
		con.blitTo( buf, ClearBufferMask.DepthBufferBit )
		# stencil init
		GL.StencilMask(-1)
		sm = buf.at.stencil.samples
		if 'RectangleFill':	
			assert sm > 0
			con.DepthTest = false
			con.ClearStencil(1)
			sa.use()
			#sb = -1; GL.GetInteger( GetPName.SampleBuffers, sb )
			#sm = -1; GL.GetInteger( GetPName.Samples, sm )
			# todo: optimize to use less passes
			using kri.Section( EnableCap.SampleMask ), kri.Section( EnableCap.StencilTest ):
				GL.StencilFunc( StencilFunction.Always, 0,0 )
				GL.StencilOp( StencilOp.Incr, StencilOp.Incr, StencilOp.Incr )
				for i in range(1,sm):
					GL.SampleMask( 0, -1<<i )
					kri.Ant.Inst.quad.draw()
		else:
			using kri.Section( EnableCap.SampleMask ):
				for i in range( sm ):
					GL.SampleMask(0,1<<i)
					con.ClearStencil(i+1)
		GL.SampleMask(0,-1)
		# color clear
		buf.mask = 3
		buf.bind()
		GL.ColorMask(true,true,true,true)
		con.ClearColor()
		if not 'DebugColor':
			debugLayer = 1
			buf.mask = 2
			buf.bind()
			sa.use()
			using kri.Section( EnableCap.StencilTest ):
				GL.StencilFunc( StencilFunction.Equal, debugLayer,-1 )
				GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Keep )
				kri.Ant.Inst.quad.draw()
		con.Multisample = true


#---------	LIGHT PRE-PASS	--------#

public class Bake( kri.rend.Basic ):
	protected final sa		= Smart()
	protected final sb		= Smart()
	protected final context	as support.light.Context
	protected final sphere	as kri.Mesh
	private final buf		as Target
	private final texDep	= par.Texture('depth')
	private final va		= kri.vb.Array()
	private final static 	geoQuality	= 1
	private final static	pif = PixelInternalFormat.Rgba

	public def constructor(init as Init, lc as support.light.Context):
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
		sphere = kri.gen.Sphere( geoQuality, OpenTK.Vector3.One )
		sphere.vbo[0].attrib( kri.Ant.Inst.attribs.vertex )
		# create white shader
		sb.add('/light/kbuf/bake_v','/empty_f')
		sb.add( *kri.Ant.Inst.libShaders )
		sb.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )

	private def drawLights(mask as byte, sx as Smart) as void:
		buf.mask = mask
		buf.bind()
		sx.useBare()
		for l in kri.Scene.Current.lights:
			continue	if l.fov != 0f
			kri.Ant.Inst.params.activate(l)
			Smart.UpdatePar()
			sphere.draw(1)
			#break	# !debug!

	public override def process(con as kri.rend.Context) as void:
		#return	# !debug!
		con.activate()
		con.Multisample = false
		texDep.Value = con.Depth
		con.SetDepth(0f,false)
		GL.CullFace( CullFaceMode.Front )
		GL.DepthFunc( DepthFunction.Gequal )
		va.bind()
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
		con.Multisample = true


#---------	LIGHT APPLICATION	--------#

public class Apply( kri.rend.tech.Meta ):
	private final buf	as kri.buf.Target
	private final pDir	= par.Texture('dir')
	private final pCol	= par.Texture('color')
	# init
	public def constructor(init as Init):
		super('lit.kbuf', false, null,
			'bump','emissive','diffuse','specular','glossiness')
		buf = init.buf
		pDir.Value = buf.at.color[0] as kri.buf.Texture
		pCol.Value = buf.at.color[1] as kri.buf.Texture
		dict.unit( pDir, pCol )
		shade('/light/kbuf/apply')
	# work
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		con.ClearColor()
		drawScene()
