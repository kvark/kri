namespace test

import OpenTK.Graphics.OpenGL


private class ShaderLink( kri.rend.Basic ):
	final sa	= kri.shade.Program()
	
	public def constructor():
		text1 = """
		#version 130
		uniform struct Spatial	{
			vec4 pos,rot;
		}sp_model;
		vec4 fun(Spatial);
		void main()	{
				gl_Position = fun(sp_model);
		}"""
		text2 = """
		#version 130
		uniform struct Spatial	{
			vec4 pos,rot;
		};
		vec4 fun(Spatial sp)	{
			return sp.pos;
		}"""
		sa.add('/lib/quat_v')
		for t in (text1,text2):
			pob = kri.shade.Object(ShaderType.VertexShader,'my',t)
			sa.add( pob )
		sa.link()


private class PolygonOffset( kri.rend.Basic ):
	final sa	= kri.shade.Program()
	final fbo	= kri.buf.Holder(mask:0)
	final vbo	= kri.vb.Attrib()

	public def constructor():
		text = """
		#version 130
		in vec4 at_vertex;
		void main()	{
			gl_Position = vec4(at_vertex.xy, at_vertex.y, 1.0);
		}"""
		pob = kri.shade.Object(ShaderType.VertexShader,'my',text)
		sa.add( pob )
		sa.add( '/empty_f' )
		sa.attrib( kri.Ant.Inst.attribs.vertex, 'at_vertex' )
		sa.link()
		t = kri.buf.Texture( dep:1,
			target:TextureTarget.Texture2DArray,
			intFormat:PixelInternalFormat.DepthComponent,
			pixFormat:PixelFormat.DepthComponent )
		fbo.resize(3,3)
		t.shadow(true)
		
	public override def process(con as kri.rend.link.Basic) as void:
		fbo.bind()
		GL.Enable( EnableCap.DepthTest )
		GL.DepthMask(true)
		GL.ClearDepth( 1.0f );
		GL.Clear( ClearBufferMask.DepthBufferBit )
		sa.bind()
		
		GL.Enable( EnableCap.PolygonOffsetFill )
		GL.PolygonOffset( 0.0f, 2.0f )
		kri.Ant.Inst.quad.draw()
		
		tmp = array[of single](9)
		tm1 = array[of single](1)
		t = fbo.at.depth as kri.buf.Texture
		t.shadow(false)
		t.genLevels()
		GL.GetTexImage(t.target, 1, PixelFormat.DepthComponent, PixelType.Float, tm1)
		GL.GetTexImage(t.target, 0, PixelFormat.DepthComponent, PixelType.Float, tmp)
		print tmp[0]


private class TextureRead( kri.rend.Basic ):
	public final buf	= kri.buf.Holder( mask:1 )
	public def constructor():
		data = (of short: 1,2,3,4)
		buf.at.color[0] = tex = kri.buf.Texture(
			wid:2, het:2,
			intFormat:PixelInternalFormat.R16i,
			pixFormat:PixelFormat.RedInteger )
		tex.init(data)
	public override def process(con as kri.rend.link.Basic) as void:
		buf.bind()
		#GL.ClearBuffer( ClearBuffer.Color, 0, (of int:5,5,5,5) )
		kri.rend.link.Basic.ClearColor()
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.BindBuffer( BufferTarget.PixelPackBuffer, 0 )
		p1 = p2 = (of short: 6,6,6,6)
		GL.ReadPixels(0,0,2,2, PixelFormat.RedInteger, PixelType.Short, p1)
		#pix = (of ushort: 0,0,0,0)
		#GL.ReadPixels(0,0,2,2, PixelFormat.RedInteger, PixelType.UnsignedShort, pix)
		buf.at.color[0].bind()
		GL.GetTexImage( TextureTarget.Texture2D, 0, PixelFormat.RedInteger, PixelType.Short, p2)
		assert p1[0] == 0 and p2[0] == 0


private class Feedback( kri.rend.Basic ):
	private final	tf		= kri.TransFeedback(1)
	private final	prog	= kri.shade.Smart()
	private final	vin		= kri.vb.Attrib()
	private final	sl		as kri.lib.Slot
	
	public def constructor(pc as kri.part.Context):
		if pc:
			sl = kri.Ant.Inst.slotParticles
			atId = pc.at_pos
		else:
			sl = kri.lib.Slot(5)
			sl.create('xxx')
			atId = sl.create('pos')
		
		ai = kri.vb.Info(
			slot:atId, integer:false, size:4,
			type:VertexAttribPointerType.Float )
		vin.Semant.Add(ai)
	
	public override def process(con as kri.rend.link.Basic) as void:
		#make program
		text = """
		#version 130
		in	vec4 at_pos;
		out	vec4 to_pos;
		void main()	{
			to_pos = vec4(10.0)-at_pos;
		}"""
		pob = kri.shade.Object(ShaderType.VertexShader,'my',text)
		prog.add(pob)
		prog.feedback(false,'to_pos')
		prog.link(sl)
		#make data
		varray = kri.vb.Array()
		varray.bind()
		dar = (of single: 1f,2f,3f,4f,5f,6f,7f,8f)
		vin.init(dar,false)
		vot = kri.vb.Attrib()
		vot.init(8*4)
		vin.attribFirst()
		#run!
		prog.use()
		tf.Bind(vot)
		using tf.catch(), kri.Discarder(true):
			GL.DrawArrays( BeginMode.Points, 0, 2 )
		q = tf.result()
		vot.read(dar)
		assert q == 2


private class DrawToStencil( kri.rend.Basic ):
	public override def process(con as kri.rend.link.Basic) as void:
		prog	= kri.shade.Smart()
		#make program
		text = """
		#version 130
		out	uint to_stencil;
		void main()	{
			to_stencil = 0;
		}"""
		pob = kri.shade.Object(ShaderType.FragmentShader,'my',text)
		prog.add('/copy_v')
		prog.add(pob)
		prog.link( kri.Ant.Inst.slotAttributes )
		#make data
		fbo = kri.buf.Holder()
		fbo.at.stencil = t = kri.buf.Texture.Stencil(0)
		fbo.resize(10,10)
		con.DepthTest = false
		GL.Disable( EnableCap.StencilTest )
		fbo.mask = 0
		fbo.bind()
		fbo.at.color[0] = t
		fbo.mask = 1
		fbo.bind()
		#run!
		prog.use()
		kri.Ant.Inst.quad.draw()
