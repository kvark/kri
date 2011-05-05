namespace kri.rend.box

import OpenTK
import OpenTK.Graphics.OpenGL


public class Tag( kri.ITag ):
	public final	buf	= kri.vb.Object()
	public def constructor():
		buf.init( 2*4*sizeof(single) )


public class Update( kri.rend.Basic ):
	private final bu	= kri.shade.Bundle()
	private final va	= kri.vb.Array()
	private final fbo	= kri.buf.Holder( mask:1 )
	private final tex	= kri.buf.Texture(0,
			PixelInternalFormat.Rgba32f, PixelFormat.Rgba )
	public def constructor():
		bu.shader.add( '/box_v', '/box_g', '/color_f' )
		tex.target = TextureTarget.Texture1D
		fbo.at.color[0] = tex
		fbo.resize(2,0)
		
	public override def process(con as kri.rend.link.Basic) as void:
		scene = kri.Scene.Current
		if not scene:	return
		d = array[of single](8)
		con.DepthTest = false
		using blend = kri.Blender():
			blend.min()
			for e in scene.entities:
				tag = e.seTag[of Tag]()
				if not tag:	continue
				#tex.init( SizedInternalFormat.Rgba32f, tag.buf )
				fbo.bind()
				con.ClearColor()
				e.render( va,bu, kri.TransFeedback.Dummy )
				kri.vb.Object.Pack = tag.buf
				tex.read( PixelType.Float )
			for e in scene.entities:
				tag = e.seTag[of Tag]()
				if not tag:	continue
				tag.buf.read(d)
				v0 = Vector3(d[0],d[1],d[2])
				v1 = Vector3(d[4],d[5],d[6])
				e.localBox.center = 0.5f*(v0-v1)
				e.localBox.hsize = -0.5f*(v0+v1)
