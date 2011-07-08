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
	final sa	= kri.shade.Mega()
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
	
		GL.Enable( EnableCap.PolygonOffsetFill )
		GL.PolygonOffset( 0.0f, 2.0f )
		kri.Ant.Inst.quad.draw(sa)
		
		t = fbo.at.depth as kri.buf.Texture
		t.shadow(false)
		t.genLevels()
		t.switchLevel(1)
		tm1 = t.read[of single]()
		t.switchLevel(0)
		tm0 = t.read[of single]()
		tm1 = null
		print tm0[0]


private class TextureRead( kri.rend.Basic ):
	public final buf	= kri.buf.Holder( mask:1 )
	public def constructor():
		data = (of short: 1,2,3,4)
		buf.at.color[0] = tex = kri.buf.Texture(
			wid:2, het:2,
			intFormat:PixelInternalFormat.R16i,
			pixFormat:PixelFormat.RedInteger )
		tex.init(data,false)
	public override def process(con as kri.rend.link.Basic) as void:
		buf.bind()
		#GL.ClearBuffer( ClearBuffer.Color, 0, (of int:5,5,5,5) )
		kri.rend.link.Basic.ClearColor()
		rect = System.Drawing.Rectangle(0,0,2,2)
		p1 = buf.read[of ushort]( PixelFormat.RedInteger, rect )
		p2 = (buf.at.color[0] as kri.buf.Texture).read[of ushort]()
		assert p1[0] == 0 and p2[0] == 0


private class Feedback( kri.rend.Basic ):
	private final	tf	= kri.TransFeedback(1)
	private final	bu	= kri.shade.Bundle()
	private final	vin	= kri.vb.Attrib()
	
	public def constructor():
		ai = kri.vb.Info( name:'pos', size:4,
			type:VertexAttribPointerType.Float,
			integer:false )
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
		bu.shader.add(pob)
		bu.shader.feedback(false,'to_pos')
		bu.link()
		#make data
		varray = kri.vb.Array()
		varray.bind()
		dar = (of single: 1f,2f,3f,4f,5f,6f,7f,8f)
		vin.init(dar,false)
		vot = kri.vb.Attrib()
		vot.init(8*4)
		assert not 'supported' # attribFirst?
		#vin.attribFirst()
		#run!
		bu.activate()
		tf.Bind(vot)
		using tf.catch(), kri.Discarder():
			GL.DrawArrays( BeginMode.Points, 0, 2 )
		q = tf.result()
		vot.read(dar,0)
		assert q == 2


private class DrawToStencil( kri.rend.Basic ):
	public override def process(con as kri.rend.link.Basic) as void:
		sa	= kri.shade.Mega()
		#make program
		text = """
		#version 130
		out	uint to_stencil;
		void main()	{
			to_stencil = 0;
		}"""
		pob = kri.shade.Object(ShaderType.FragmentShader,'my',text)
		sa.add('/copy_v')
		sa.add(pob)
		sa.link()
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
		kri.Ant.Inst.quad.draw(sa)


private class MultiResolve( kri.rend.Basic ):
	public override def process(con as kri.rend.link.Basic) as void:
		GL.DepthMask(true)
		f0 = kri.buf.Holder()
		f0.at.depth = td = kri.buf.Texture.Depth(1)
		td.wid = td.het = 100
		#td.initMulti(true)
		f0.bind()
		con.ClearDepth(1.0)
		f1 = kri.buf.Holder()
		f1.at.depth = td = kri.buf.Texture.Depth(0)
		td.wid = td.het = 100
		#td.initMulti(true)
		f1.bind()
		con.ClearDepth(1.0)
		GL.BindTexture( TextureTarget.Texture2D, 0 )
		GL.BindTexture( TextureTarget.Texture2DMultisample, 0 )
		f0.copyTo(f1, ClearBufferMask.DepthBufferBit)


private class Geometry( kri.rend.Basic ):
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate(false)
		bu = kri.shade.Bundle()
		bu.shader.add('/cull/draw_v','/cull/draw_g','/white_f')
		m = kri.Mesh(BeginMode.Points)
		m.nVert = 256
		v0 = kri.vb.Attrib()
		kri.Help.enrich(v0,4,'pos','rot')
		v1 = kri.vb.Attrib()
		kri.Help.enrich(v1,4,'low','hai')
		m.vbo.AddRange((v0,v1))
		m.allocate()
		vao = kri.vb.Array()
		m.render(vao,bu,null)
