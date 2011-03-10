namespace support.pick

import OpenTK.Graphics.OpenGL
import OpenTK.Input

public class Tag( kri.ITag ):
	public pick	as callable(kri.Entity, OpenTK.Vector3) as void	= null
	

public class Render( kri.rend.Basic ):
	private final buf	= kri.buf.Holder( mask:1 )
	private final va	= kri.vb.Array()
	private final sa	= kri.shade.Smart()
	private final qlog	as uint
	private final pInd	= kri.shade.par.Value[of single]('index')
	private final mouse	as MouseDevice
	private coord	=	(of uint: 0,0)
	#debug data
	private final sb	= kri.shade.Smart()
	private final pTex	= kri.shade.par.Value[of kri.buf.Texture]('input')

	public def constructor(win as kri.Window, reduct as uint, numorder as uint):
		super(false)
		active = false
		qlog = reduct
		mouse = win.Mouse
		mouse.ButtonDown += ev
		# make buffer
		assert numorder<=16
		buf.at.depth = kri.buf.Texture.Depth(0)
		buf.at.color[0] = kri.buf.Texture(
			intFormat:PixelInternalFormat.Rgba16 )
		# make shader
		sa.add('/zcull_v', '/pick_f', '/lib/tool_v', '/lib/quat_v', '/lib/fixed_v')
		d = kri.shade.rep.Dict()
		d.var(pInd)
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict, d )
		d.unit(pTex)
		sb.add('/copy_v', '/copy_f')
		sb.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict, d )
	
	def destructor():
		mouse.ButtonDown -= ev

	public override def setup(pl as kri.buf.Plane) as bool:
		buf.resize( pl.wid>>qlog, pl.het>>qlog)
		return true

	public override def process(con as kri.rend.link.Basic) as void:
		buf.bind()
		con.SetDepth(0f, true)
		con.ClearDepth( 1f )
		con.ClearColor()
		#GL.ClearBuffer(ClearBuffer.Color, 0, (of uint:10,10,10,10))
		va.bind()
		pInd.Value = 0f
		ents = List[of kri.Entity](e for e in kri.Scene.Current.entities if e.seTag[of Tag]()).ToArray()
		for i in range(ents.Length):
			pInd.Value = (i+1f) / ((1<<16)-1)
			e = ents[i]
			e.enable( true, (kri.Ant.Inst.attribs.vertex,) )
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.use()
			e.mesh.draw(1)
		if not 'Debug':
			con.activate( con.Target.Same, 0f, false )
			pTex.Value = buf.at.color[0] as kri.buf.Texture
			sb.use()
			kri.Ant.Inst.quad.draw()
			return
		# react, todo: use PBO and actually read on demand
		buf.bind()
		GL.BindBuffer( BufferTarget.PixelPackBuffer, 0 )
		index = (of ushort: ushort.MaxValue )
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.ReadPixels( coord[0],coord[1], 1,1, PixelFormat.Red, PixelType.UnsignedShort, index )
		active = false
		return if not index[0]
		GL.ReadBuffer( cast(ReadBufferMode,0) )
		val = (of single: single.NaN )
		GL.ReadPixels(coord[0], coord[1], 1,1, PixelFormat.DepthComponent, PixelType.Float, val)
		pl = buf.at.color[0]
		vin = OpenTK.Vector3(coord[0]*1f / pl.wid, coord[1]*1f / pl.het, val[0])
		point = kri.Camera.Current.toWorld(vin)
		# call the react method
		e = ents[ index[0]-1 ]
		sp = (e.node.World if e.node else kri.Spatial.Identity)
		sp.inverse()
		fun = e.seTag[of Tag]().pick
		fun( e, sp.byPoint(point) )	if fun

	public def ev(ob as object, arg as OpenTK.Input.MouseButtonEventArgs) as void:
		active = true
		coord[0] = (mouse.X >> qlog)
		coord[1] = buf.at.color[0].het - (mouse.Y >> qlog)
