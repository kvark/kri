namespace kri.kit.pick

import System
import OpenTK.Graphics.OpenGL

public class Tag(kri.ITag):
	#todo: interface with pick function?
	public pick as callable(kri.Entity, OpenTK.Vector3) as void	= null
	

public class Render(kri.rend.Basic):
	private final buf	= kri.frame.Buffer()
	private final va	= kri.vb.Array()
	private final sa	= kri.shade.Smart()
	private final qlog	as uint
	private final pInd	= kri.shade.par.Value[of int]()
	private final ptype	as PixelType
	private final mouse	= kri.Ant.Inst.Mouse
	private coord	=	(of uint: 0,0)

	public def constructor(reduct as uint, numorder as uint):
		super(false)
		active = false
		qlog = reduct
		mouse.ButtonDown += ev
		# make buffer
		buf.A[-1].new(0)
		buf.A[0].new( kri.Texture.Class.Index, numorder, TextureTarget.TextureRectangle )
		# make shader
		sa.add('/zcull_v', '/pick_f', 'tool', 'quat', 'fixed')
		d = kri.shade.rep.Dict()
		d.add('index',pInd)
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict, d )
		# set pix type
		pbyte = PixelType.Byte
		ptype = (pbyte, pbyte, PixelType.UnsignedShort,	pbyte, PixelType.UnsignedInt) [numorder>>3]
	
	def destructor():
		mouse.ButtonDown -= ev

	public override def setup(far as kri.frame.Array) as bool:
		buf.init(far.getW>>qlog, far.getH>>qlog)
		return true

	public override def process(con as kri.rend.Context) as void:
		buf.activate()
		con.SetDepth(0f, true)
		con.ClearDepth( 1f )
		con.ClearColor( OpenTK.Graphics.Color4.Blue )
		GL.ClearBuffer(ClearBuffer.Color, 0, (of uint:10,10,10,10))
		va.bind()
		pInd.Value = 0
		for e in kri.Scene.Current.entities:
			pInd.Value = pInd.Value+1
			fp = e.seTag[of Tag]()
			continue	if not fp
			e.enable( (kri.Ant.Inst.attribs.vertex,) )
			sa.use()
			e.mesh.draw()
		# react, todo: use PBO and actually read on demand
		GL.ReadBuffer( ReadBufferMode.ColorAttachment0 )
		GL.BindBuffer( BufferTarget.PixelPackBuffer, 0 )
		val = (of byte: 20,20,20,20)
		GL.ReadPixels(coord[0],coord[1],1,1, PixelFormat.RedInteger, PixelType.Byte, val)
		#val = array[of byte](buf.getW * buf.getH)
		#GL.ReadPixels(0,0,buf.getW,buf.getH, PixelFormat.RedInteger, PixelType.Byte, val)
		active = false
		return if not val[0]
		depth = 0.7f	# todo: read from the depth buffer
		vin = OpenTK.Vector3(coord[0]*1f / buf.getW, coord[1]*1f / buf.getH, depth)
		point = kri.Camera.Current.toWorld(vin)
		# call the react method
		e = kri.Scene.Current.entities[ val[0]-1 ]
		sp = (e.node.World if e.node else kri.Spatial.Identity)
		sp.inverse()
		e.seTag[of Tag]().pick( e, sp.byPoint(point) )

	public def ev(ob as object, arg as OpenTK.Input.MouseButtonEventArgs) as void:
		active = true
		coord[0] = mouse.X >> qlog
		coord[1] = mouse.Y >> qlog
