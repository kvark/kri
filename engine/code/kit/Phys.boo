namespace kri.kit.phys

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PHYSICS		--------#

public class Core:
	private final fbo	= kri.frame.Buffer()
	private final cam	= kri.Camera()
	private final sa	= kri.shade.Smart()
	private final tid	as int
	private final pbo	= kri.vb.Object( BufferTarget.PixelPackBuffer )
	private final pId	= kri.shade.par.Value[of single]('object_id')
	
	public def constructor( ord as int, techId as int ):
		# init FBO
		fbo.init(1<<ord,1<<ord)
		tt = TextureTarget.Texture2D
		fbo.A[-2].new( 0, tt )
		fbo.A[0].new( PixelInternalFormat.Rg16 ,tt )
		pbo.init( 5<<(2*ord) )
		# init shader
		tid = techId
		d = kri.shade.rep.Dict()
		d.var(pId)
		sa.add('/zcull_v','/physics_f','tool','quat','fixed')
		sa.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )

	private def drawAll(scene as kri.Scene) as void:
		for i in range(scene.entities.Count):
			e = scene.entities[i]
			va = e.va[tid]
			continue	if not va or va == kri.vb.Array.Default
			e.va[tid].bind()
			pId.Value = (i+1f) / (1<<16)
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.updatePar()
			e.mesh.draw(1)

	public def tick(s as kri.Scene) as void:
		# prepare the camera
		kri.Ant.Inst.params.activate(cam)
		sa.use()
		# prepare buffer
		fbo.activate(1)
		GL.ClearColor(0f,0f,0f,1f)
		GL.ClearDepth(1f)
		GL.ClearStencil(0)
		GL.Clear(
			ClearBufferMask.ColorBufferBit |
			ClearBufferMask.DepthBufferBit |
			ClearBufferMask.StencilBufferBit )
		using kri.Section( EnableCap.DepthTest ):
			GL.ColorMask(true,false,false,false)
			GL.DepthMask(true)
			GL.DepthFunc( DepthFunction.Always )
			GL.PolygonMode( MaterialFace.FrontAndBack, PolygonMode.Line )
			drawAll(s)
			GL.ColorMask(false,true,false,false)
			GL.DepthMask(false)
			GL.DepthFunc( DepthFunction.Less )
			GL.PolygonMode( MaterialFace.FrontAndBack, PolygonMode.Fill )
			using kri.Section( EnableCap.StencilTest ):
				GL.CullFace( CullFaceMode.Back )
				GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Incr )
				drawAll(s)
				GL.CullFace( CullFaceMode.Front )
				GL.StencilOp( StencilOp.Keep, StencilOp.Keep, StencilOp.Decr )
				drawAll(s)
				GL.CullFace( CullFaceMode.Back )
		# read back result
		GL.ColorMask(true,true,true,true)
		pbo.bind()
		size = fbo.Width * fbo.Height
		GL.ReadBuffer( cast(ReadBufferMode,0) )
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.StencilIndex, PixelType.Byte, IntPtr.Zero )
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.ReadPixels(0,0, fbo.Width, fbo.Height, PixelFormat.Rg, PixelType.UnsignedShort, IntPtr(size) )
		dar = array[of byte]( 5*size )
		pbo.read(dar)
		for i in range(size):
			continue	if not dar[i]
			cs = dar[i]
			ca = dar[size +i*4 +0]
			cb = dar[size +i*4 +2]
			cs = ca = cb