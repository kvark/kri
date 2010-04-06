namespace kri.kit.pick

import OpenTK.Graphics.OpenGL

public class Tag( kri.ITag ):
	#todo: interface with pick function?
	public pick	as callable(kri.Entity, OpenTK.Vector3) as void	= null
	

public class Render( kri.rend.Basic ):
	private final buf	= kri.frame.Buffer()
	private final va	= kri.vb.Array()
	private final sa	= kri.shade.Smart()
	private final qlog	as uint
	private final pInd	= kri.shade.par.Value[of single]()
	private final ptype	as PixelType
	private final mouse	= kri.Ant.Inst.Mouse
	private coord	=	(of uint: 0,0)
	#debug data
	private final sb	= kri.shade.Smart()
	private final pTex	= kri.shade.par.Texture(0,'input')

	public def constructor(reduct as uint, numorder as uint):
		super(false)
		active = false
		qlog = reduct
		mouse.ButtonDown += ev
		# make buffer
		buf.A[-1].new(0)
		assert numorder<=16
		buf.A[0].new( kri.Texture.Class.Index, 16, TextureTarget.TextureRectangle )
		# make shader
		sa.add('/zcull_v', '/pick_f', 'tool', 'quat', 'fixed')
		d = kri.shade.rep.Dict()
		d.add('index',pInd)
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict, d )
		d.unit( pTex )
		sb.add('/copy_v', '/copy_f')
		sb.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict, d )
		# set pix type
		ptype = PixelType.Float
	
	def destructor():
		mouse.ButtonDown -= ev

	public override def setup(far as kri.frame.Array) as bool:
		buf.init(far.getW>>qlog, far.getH>>qlog)
		return true

	public override def process(con as kri.rend.Context) as void:
		buf.activate(1)
		con.SetDepth(0f, true)
		con.ClearDepth( 1f )
		con.ClearColor()
		#GL.ClearBuffer(ClearBuffer.Color, 0, (of uint:10,10,10,10))
		va.bind()
		pInd.Value = 0f
		ents = array(e for e in kri.Scene.Current.entities if e.seTag[of Tag]())
		for i in range(ents.Length):
			pInd.Value = (i+0.5f) / ents.Length
			e = ents[i]
			e.enable( (kri.Ant.Inst.attribs.vertex,) )
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.use()
			e.mesh.draw()
		if not 'Debug':
			con.activate(true,0f,false)
			pTex.Value = buf.A[0].Tex
			sb.use()
			kri.Ant.Inst.emitQuad()
			return
		# react, todo: use PBO and actually read on demand
		GL.BindBuffer( BufferTarget.PixelPackBuffer, 0 )
		val = (of single: single.NaN)
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.ReadPixels(coord[0], coord[1], 1,1, PixelFormat.Red, ptype, val)
		active = false
		return if val[0] == 0f
		index = cast(int, val[0]*ents.Length)
		val[0] = single.NaN	# depth read dosn't seem to work
		GL.ReadBuffer( cast(ReadBufferMode,0) )
		GL.ReadPixels(coord[0], coord[1], 1,1, PixelFormat.DepthComponent, PixelType.Float, val)
		vin = OpenTK.Vector3(coord[0]*1f / buf.getW, coord[1]*1f / buf.getH, val[0])
		point = kri.Camera.Current.toWorld(vin)
		# call the react method
		e = ents[ index ]
		sp = (e.node.World if e.node else kri.Spatial.Identity)
		sp.inverse()
		fun = e.seTag[of Tag]().pick
		fun( e, sp.byPoint(point) )	if fun

	public def ev(ob as object, arg as OpenTK.Input.MouseButtonEventArgs) as void:
		active = true
		coord[0] = (mouse.X >> qlog)
		coord[1] = buf.getH - (mouse.Y >> qlog)
