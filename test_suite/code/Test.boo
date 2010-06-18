namespace test

import OpenTK.Graphics.OpenGL

private class Link( kri.rend.Basic ):
	final sa	= kri.shade.Program()
	
	public def constructor():
		super(false)
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
		sa.add('quat')
		for t in (text1,text2):
			pob = kri.shade.Object(ShaderType.VertexShader,'my',t)
			sa.add( pob )
		sa.link()


private class Offset( kri.rend.Basic ):
	final sa	= kri.shade.Program()
	final fbo	= kri.frame.Buffer()
	final vbo	= kri.vb.Attrib()

	public def constructor():
		super(false)
		text = """
		#version 130
		in vec4 at_vertex;
		void main()	{
			gl_Position = vec4(at_vertex.xy, at_vertex.y, 1.0);
		}"""
		pob = kri.shade.Object(ShaderType.VertexShader,'my',text)
		sa.add( pob )
		sa.add( 'empty' )
		sa.attrib( kri.Ant.Inst.attribs.vertex, 'at_vertex' )
		sa.link()
		fbo.init(3,3)
		t = kri.Texture( TextureTarget.Texture2DArray )
		t.bind()
		kri.Texture.InitArrayDepth(3,3,1)
		fbo.A[-1].layer(t,0)
		fbo.mask = 0
		
	public override def process(con as kri.rend.Context) as void:
		fbo.activate()
		GL.Enable( EnableCap.DepthTest )
		GL.DepthMask(true)
		GL.ClearDepth( 1.0f );
		GL.Clear( ClearBufferMask.DepthBufferBit )
		sa.use()
		
		GL.Enable( EnableCap.PolygonOffsetFill )
		GL.PolygonOffset( 0.0f, 2.0f )
		kri.Ant.Inst.emitQuad()
		
		tmp = array[of single](9)
		tm1 = array[of single](1)
		t = fbo.A[-1].Tex
		t.bind()
		kri.Texture.Shadow(false)
		kri.Texture.GenLevels()
		GL.GetTexImage(t.type, 1, PixelFormat.DepthComponent, PixelType.Float, tm1)
		GL.GetTexImage(t.type, 0, PixelFormat.DepthComponent, PixelType.Float, tmp)
		print tmp[0]


private class Read( kri.rend.Basic ):
	public final buf	= kri.frame.Buffer()
	public def constructor():
		super(false)
		buf.init(2,2)
		buf.A[0].Tex = tex = kri.Texture( TextureTarget.Texture2D )
		tex.bind()
		data = (of short: 1,2,3,4)
		GL.TexImage2D( TextureTarget.Texture2D, 0, PixelInternalFormat.R16i, 2,2,0, PixelFormat.RedInteger, PixelType.Short, data)
	public override def process(con as kri.rend.Context) as void:
		buf.activate()
		#GL.ClearBuffer( ClearBuffer.Color, 0, (of int:5,5,5,5) )
		kri.rend.Context.ClearColor()
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.BindBuffer( BufferTarget.PixelPackBuffer, 0 )
		p1 = p2 = (of short: 6,6,6,6)
		GL.ReadPixels(0,0,2,2, PixelFormat.RedInteger, PixelType.Short, p1)
		#pix = (of ushort: 0,0,0,0)
		#GL.ReadPixels(0,0,2,2, PixelFormat.RedInteger, PixelType.UnsignedShort, pix)
		buf.A[0].Tex.bind()
		GL.GetTexImage( TextureTarget.Texture2D, 0, PixelFormat.RedInteger, PixelType.Short, p2)
		assert p1[0] == 0 and p2[0] == 0


private class Feedback( kri.rend.Basic ):
	private final	tf		= kri.TransFeedback(1)
	private final	prog	= kri.shade.Smart()
	private final	vin		= kri.vb.Attrib()
	private final	sl		as kri.lib.Slot
	
	public def constructor(pc as kri.part.Context):
		super(false)
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
	
	public override def process(con as kri.rend.Context) as void:
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
