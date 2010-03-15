namespace kri.rend

import System
import OpenTK.Graphics.OpenGL

#---------	RENDER PHYSICS		--------#

public class Physics:
	public final fbo	= kri.frame.Buffer()
	public def constructor(ord as int):
		fbo.init(1<<ord,1<<ord)
		fbo.A[-2].new(8, TextureTarget.Texture2D)
	private def drawAll(scene as kri.Scene) as void:
		tid = kri.Ant.Inst.slotTechniques.find('zcull')
		assert tid>=0
		for e in scene.entities:
			e.va[tid].bind()
			e.mesh.draw()

	public def tick(s as kri.Scene) as void:
		//missed step: prepare the camera
		fbo.mask = 0
		fbo.activate()
		GL.ClearDepth(1f)
		GL.ClearStencil(0)
		GL.Clear(ClearBufferMask.ColorBufferBit |
			ClearBufferMask.DepthBufferBit |
			ClearBufferMask.StencilBufferBit)
		using kri.Section(EnableCap.DepthTest)
		
		GL.DepthMask(true)
		GL.DepthFunc(DepthFunction.Always)
		GL.PolygonMode(MaterialFace.FrontAndBack, PolygonMode.Line)
		drawAll(s)
		GL.DepthMask(false)
		GL.DepthFunc(DepthFunction.Less)
		GL.PolygonMode(MaterialFace.FrontAndBack, PolygonMode.Fill)
		using kri.Section(EnableCap.StencilTest)
		GL.CullFace(CullFaceMode.Back)
		GL.StencilOp(StencilOp.Keep, StencilOp.Keep, StencilOp.Incr)
		drawAll(s)
		GL.CullFace(CullFaceMode.Front)
		GL.StencilOp(StencilOp.Keep, StencilOp.Keep, StencilOp.Decr)
		drawAll(s)
		GL.CullFace(CullFaceMode.Back)

