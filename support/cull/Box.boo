namespace support.cull.box

import OpenTK
import OpenTK.Graphics.OpenGL


public class Tag( kri.ITag ):
	public	final	buf		as kri.vb.Object
	public	final	index	as uint
	private	animated	= false
	private	stamp		as uint	= 0
	
	public def check(bv as kri.vb.Object) as bool:
		if animated != (bv!=null):
			animated = not animated
			stamp = 0
		if stamp == bv.TimeStamp:
			return false
		stamp = bv.TimeStamp
		return true
	
	public def constructor(b as kri.vb.Object, ind as uint):
		buf = b
		index = ind



public class Update( kri.rend.Basic ):
	public	final maxn	= 256
	private next		= 0
	public	final data	= kri.vb.Attrib()
	private final bu	= kri.shade.Bundle()
	public	final va	= kri.vb.Array()
	private final fbo	= kri.buf.Holder( mask:1 )
	private final tex	= kri.buf.Texture(0,
			PixelInternalFormat.Rgba32f, PixelFormat.Rgba )
	
	public def constructor():
		data.init( maxn*2*4*sizeof(single) )
		bu.shader.add( '/box_v', '/box_g', '/color_f' )
		tex.target = TextureTarget.Texture1D
		fbo.at.color[0] = tex
		fbo.resize(2*maxn,0)
		kri.Help.enrich(data,4,'low','hai')
	
	public def genTag() as Tag:
		if next>=maxn:
			kri.lib.Journal.Log('Box: objects limit reached')
			return null
		return Tag(data,next++)
		
	public override def process(con as kri.rend.link.Basic) as void:
		scene = kri.Scene.Current
		if not scene:	return
		d = array[of single](8)
		con.DepthTest = false
		using blend = kri.Blender():
			blend.min()
			for e in scene.entities:
				tag = e.seTag[of Tag]()
				bv = e.findAny('vertex')
				if not (tag and tag.check(bv)):
					continue
				#tex.init( SizedInternalFormat.Rgba32f, tag.buf )
				fbo.bind()
				i = 2 * tag.index
				GL.Viewport(i,0,i+2,1)
				v = single.PositiveInfinity
				GL.ClearBuffer( ClearBuffer.Color, 0, (v,v,v,1f) )
				e.render( va,bu, kri.TransFeedback.Dummy )
				kri.vb.Object.Pack = tag.buf
				tex.read( PixelType.Float )
				# read back
				data.read(d,4*i)
				v0 = Vector3(d[0],d[1],d[2])
				v1 = Vector3(d[4],d[5],d[6])
				e.localBox.center = 0.5f*(v0-v1)
				e.localBox.hsize = -0.5f*(v0+v1)
