namespace kri.kit.phys

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PHYSICS		--------#

public class Core:
	private final fbo	= kri.frame.Buffer()
	private final cam	= kri.Camera()
	private final sa	= kri.shade.Smart()
	private final sb	= kri.shade.Smart()
	private final tid	as int
	private final pbo	= kri.vb.Object( BufferTarget.PixelPackBuffer )
	private final pId	= kri.shade.par.Value[of single]('object_id')
	private final big	as bool
	
	public Color	as kri.Texture:
		get: return fbo.A[-0].Tex
	public Stencil	as kri.Texture:
		get: return fbo.A[-2].Tex
	
	public def constructor( ord as byte, large as bool, techId as int ):
		big = large
		# init FBO
		fbo.init(1<<ord,1<<ord)
		tt = TextureTarget.Texture2D
		fbo.A[-2].new( 0, tt )
		pif = (PixelInternalFormat.Rg8, PixelInternalFormat.Rg16)[large]
		fbo.A[0].new( pif,tt )
		pbo.init( (3,5)[large]<<(2*ord) )
		# init shader
		tid = techId
		d = kri.shade.rep.Dict()
		d.var(pId)
		sa.add('/zcull_v','/physics_f','tool','quat','fixed')
		sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )

	private def drawAll(scene as kri.Scene) as void:
		kid = 1f / ((1 << (8,16)[big]) - 1f)
		for i in range(scene.entities.Count):
			e = scene.entities[i]
			va = e.va[tid]
			continue	if not va or va == kri.vb.Array.Default
			e.va[tid].bind()
			pId.Value = (i+1.5f)*kid + 0.5f
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.updatePar()
			e.mesh.draw(1)

	public def tick(s as kri.Scene) as void:
		# prepare the camera
		kri.Ant.Inst.params.activate( cam )
		kri.Ant.Inst.params.activate( s.cameras[0] )
		sa.use()
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

		using kri.Section( EnableCap.DepthTest ):
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
		GL.ColorMask(true,true,true,true)
		#fbo.A[1].layer( fbo.A[-2].Tex, 1 )
		#fbo.A[2].layer( fbo.A[-0].Tex, 1 )

		# read back result
		pbo.bind()
		size = fbo.Width * fbo.Height
		GL.ReadBuffer( cast(ReadBufferMode,0) )
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.StencilIndex, PixelType.Byte, IntPtr.Zero )
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		pt = (PixelType.UnsignedByte, PixelType.UnsignedShort)[big]
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.Rg, pt, IntPtr(size) )
		# debug: extract result
		es = (1,2)[big]
		dar = array[of byte]( size*(1+2*es) )
		pbo.read(dar)
		for i in range(size):
			cs = dar[i]
			ca = dar[size + (i*2+0)*es]
			cb = dar[size + (i*2+1)*es]
			continue	if not cs or ca==cb
			cs = ca = cb
