namespace support.phys

import System
import OpenTK.Graphics.OpenGL


public class Simulator( kri.ani.sim.Native ):
	public final pr	as	Core
	public def constructor( s as kri.Scene, ord as int, rz as kri.rend.EarlyZ ):
		super(s)
		pr = Core( ord, true, rz.tid )
	protected override def onDelta(delta as double) as uint:
		super(delta)
		pr.tick(scene)
		return 0


#---------	RENDER PHYSICS		--------#

public class Core:
	private final fbo	= kri.frame.Buffer(0, TextureTarget.Texture2D )
	private final cam	= kri.Camera()
	private final sa	= kri.shade.Smart()
	private final sb	= kri.shade.Smart()
	private final tid	as int
	private final pbo	= kri.vb.Object( BufferTarget.PixelPackBuffer )
	private final pId	= kri.shade.par.Value[of single]('object_id')
	private final big	as bool
	
	public Color	as kri.buf.Texture:
		get: return fbo.A[-0].Tex
	public Stencil	as kri.buf.Texture:
		get: return fbo.A[-2].Tex
	
	public def constructor( ord as byte, large as bool, techId as int ):
		big = large
		# init FBO
		fbo.init(1<<ord,1<<ord)
		tSten = fbo.emitAuto(-2,0)
		tSten.pixFormat = PixelFormat.DepthStencil
		pif = (PixelInternalFormat.Rg8, PixelInternalFormat.Rg16)[large]
		tColor = fbo.emit(0,pif)
		# setup target parameters
		fbo.activate(1)
		for tex in (tSten,tColor):
			tex.filt(false,false)
			tex.genLevels()
		# 8 bit stencil + 2*[8,16] bit color
		pbo.init( (3,5)[large]<<(2*ord) )
		# init shader
		tid = techId
		d = kri.shade.rep.Dict()
		pSten	= kri.shade.par.Texture('sten')
		pColor	= kri.shade.par.Texture('color')
		pSten.Value	= tSten
		pColor.Value = tColor
		d.unit(pSten,pColor)
		d.var(pId)
		# create draw program
		sa.add('/zcull_v','/physics_f')
		sa.add( *kri.Ant.Inst.libShaders )
		sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
		# create down-sample program
		sb.add('/copy_v','/filter/phys_max_f')
		sb.fragout('to_sten','to_color')
		sb.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )

	private def drawAll(scene as kri.Scene) as void:
		kid = 1f / ((1 << (8,16)[big]) - 1f)
		for i in range(scene.entities.Count):
			e = scene.entities[i]
			va = e.va[tid]
			continue	if va in (null,kri.vb.Array.Default)
			e.va[tid].bind()
			pId.Value = (i+1.5f)*kid + 0.5f
			kri.Ant.Inst.params.modelView.activate( e.node )
			kri.shade.Smart.UpdatePar()
			e.mesh.draw(1)

	public def tick(s as kri.Scene) as void:
		# prepare the camera
		kri.Ant.Inst.params.activate( cam )
		kri.Ant.Inst.params.activate( s.cameras[0] )
		sa.useBare()
		# prepare buffer
		fbo.activate(1)
		GL.DepthMask(true)
		GL.StencilMask(-1)
		GL.ClearColor(0f,0f,0f,1f)
		GL.ClearDepth(1f)
		GL.ClearStencil(0)
		GL.Clear(
			ClearBufferMask.ColorBufferBit |
			ClearBufferMask.DepthBufferBit |
			ClearBufferMask.StencilBufferBit )

		GL.Enable( EnableCap.DepthTest )
		GL.Disable( EnableCap.PolygonOffsetLine )
		GL.ColorMask(true,false,false,false)
		GL.DepthFunc( DepthFunction.Always )
		GL.PolygonMode( MaterialFace.FrontAndBack, PolygonMode.Line )
		drawAll(s)
		GL.DepthMask(false)
		GL.ColorMask(false,true,false,false)
		GL.DepthFunc( DepthFunction.Lequal )
		GL.PolygonMode( MaterialFace.FrontAndBack, PolygonMode.Fill )
		GL.Enable( EnableCap.PolygonOffsetFill )
		GL.StencilFunc( StencilFunction.Always, 0,0 )
		using kri.Section( EnableCap.StencilTest ):
			GL.PolygonOffset(1f,1f)
			GL.CullFace( CullFaceMode.Back )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Incr )
			drawAll(s)
			GL.PolygonOffset(-1f,-1f)
			GL.CullFace( CullFaceMode.Front )
			GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Decr )
			drawAll(s)
			GL.CullFace( CullFaceMode.Back )

		# resize the map
		GL.Disable( EnableCap.PolygonOffsetFill )
		GL.ColorMask(true,true,true,true)
		
		GL.Disable( EnableCap.DepthTest )
		sb.use()
		tc = fbo.A[0].Tex
		ts = fbo.A[-2].Tex
		for i in range(3):
			for tex in (tc,ts):
				tex.setLevels(i,i+1)
			GL.FramebufferTexture2D( FramebufferTarget.DrawFramebuffer,
				FramebufferAttachment.ColorAttachment0, tc.target, tc.HardId, i+1)
			GL.FramebufferTexture2D( FramebufferTarget.DrawFramebuffer,
				FramebufferAttachment.ColorAttachment1, ts.target, ts.HardId, i+1)
			
		# read back result
		pbo.bind()
		fbo.activate(false)
		size = fbo.Width * fbo.Height
		GL.ReadBuffer( cast(ReadBufferMode,0) )
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.StencilIndex, PixelType.Byte, IntPtr.Zero )
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		pt = (PixelType.UnsignedByte, PixelType.UnsignedShort)[big]
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.Rg, pt, IntPtr(size) )
		# debug: extract result
		es = (1,2)[big]
		dar = array[of byte]( size*(1+2*es) )
		for i in range(dar.Length):
			dar[i] = 123
		pbo.read(dar)
		# readpixels don't work on 10.6
		for i in range(size):
			cs = dar[i]
			ca = dar[size + (i*2+0)*es]
			cb = dar[size + (i*2+1)*es]
			continue	if not cs or ca==cb
			cs = ca = cb
