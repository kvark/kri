namespace support.cull.box

import OpenTK.Graphics.OpenGL


public class Fill( kri.rend.Basic ):
	private final bu	= kri.shade.Bundle()
	public	final va	= kri.vb.Array()
	private final fbo	= kri.buf.Holder( mask:1 )
	private final tex	= kri.buf.Texture(0,
			PixelInternalFormat.Rgba32f, PixelFormat.Rgba )
	private final model 	as (OpenTK.Vector4)
	private final con		as support.cull.Context
	private final mesh		= kri.Mesh( BeginMode.Points )
	
	public def constructor(ct as support.cull.Context):
		model = array[of OpenTK.Vector4]( ct.maxn*2 )
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
		doWork = con.spatial.Allocated==0
		using blend = kri.Blender(), kri.Section(EnableCap.ScissorTest):
			blend.min()
			for e in scene.entities:
				e.frameVisible.Clear()
				tag = e.seTag[of Tag]()
				bv = e.findAny('vertex')
				if not (tag and tag.check(bv)):
					continue
				if tag.Index<0:
					tag.Index = con.genId()
				tag.fresh = doWork = true
				i = 2 * tag.Index
				GL.Scissor	( i,0, 2,1 )
				GL.ClearBuffer( ClearBuffer.Color, 0, (v,v,v,1f) )
				GL.Viewport	( i,0, 2,1 )
				e.render( va,bu, kri.TransFeedback.Dummy )
				spa = kri.Node.SafeWorld( e.node )
				model[i+0] = kri.Spatial.GetPos(spa)
				model[i+1] = kri.Spatial.GetRot(spa)
		if doWork:
			# upload spatial data array
			con.spatial.init(model,true)
			# read from texture into VBO
			fbo.bindRead(true)
			GL.Viewport( 0,0, con.maxn*2,1 )
			kri.vb.Object.Pack = con.bound
			tex.read( PixelType.Float )
