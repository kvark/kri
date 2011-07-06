namespace support.cull.box

import OpenTK
import OpenTK.Graphics.OpenGL


public class Tag( kri.ITag ):
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
	
	public def constructor(ind as uint):
		index = ind



public class Update( kri.rend.Basic ):
	private final bu	= kri.shade.Bundle()
	public	final va	= kri.vb.Array()
	private final fbo	= kri.buf.Holder( mask:1 )
	private final tex	= kri.buf.Texture(0,
			PixelInternalFormat.Rgba32f, PixelFormat.Rgba )
	private final rez		as (single)
	private final model 	as (Vector4)
	private final con		as support.cull.Context
	private final spatial	as kri.vb.Object
	private final bound		as kri.vb.Object
	
	public def constructor(ct as support.cull.Context):
		rez = array[of single]( ct.maxn*4*2 )
		model = array[of Vector4]( ct.maxn*2 )
		con = ct
		bu.shader.add( '/box_v', '/box_g', '/color_f' )
		tex.target = TextureTarget.Texture1D
		fbo.at.color[0] = tex
		fbo.resize( ct.maxn*2, 0 )
	
	public override def process(link as kri.rend.link.Basic) as void:
		scene = kri.Scene.Current
		if not scene:	return
		link.DepthTest = false
		fbo.bind()
		v = single.PositiveInfinity
		GL.ClearBuffer( ClearBuffer.Color, 0, (v,v,v,1f) )
		using blend = kri.Blender():
			blend.min()
			for e in scene.entities:
				e.frameVisible.Clear()
				tag = e.seTag[of Tag]()
				#bv = e.findAny('vertex')
				if not tag:	continue	#and tag.check(bv)):
				i = 2 * tag.index
				GL.Viewport( i,0, 2,1 )		
				e.render( va,bu, kri.TransFeedback.Dummy )
				spa = kri.Node.SafeWorld( e.node )
				model[i+0] = kri.Spatial.GetPos(spa)
				model[i+1] = kri.Spatial.GetRot(spa)
		# upload spatial data array
		con.spatial.init(model,true)
		# read back
		fbo.bindRead(true)
		GL.Viewport( 0,0, con.maxn*2,1 )
		kri.vb.Object.Pack = con.bound
		tex.read( PixelType.Float )
		con.bound.read(rez,0)
		# update local boxes
		for e in scene.entities:
			tag = e.seTag[of Tag]()
			if not tag:	continue
			i = 2*4 * tag.index
			v0 = Vector3(rez[i+0],rez[i+1],rez[i+2])
			v1 = Vector3(rez[i+4],rez[i+5],rez[i+6])
			e.localBox.center = 0.5f*(v0-v1)
			e.localBox.hsize = -0.5f*(v0+v1)
