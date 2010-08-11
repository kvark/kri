namespace demo.water

import System
import OpenTK
import OpenTK.Graphics.OpenGL


private class Context:
	public final buf	= kri.frame.Buffer()
	public final tKernel	= kri.Texture( TextureTarget.Texture2D )
	public final dict		= kri.shade.rep.Dict()
	public final calc	= Calculator(10000,0.001f,1f)
	private final G0	as single	= calc.gen({x| return 1f})
	private kernel		as byte		= 0
	
	public def constructor():
		# buffer attachments
		border = (of single: 0f,0f,0f,0f)
		for i in range(3):
			t = buf.emit(i, PixelInternalFormat.R16f )
			t.setState(0,false,false)
			GL.TexParameter( t.target, TextureParameterName.TextureBorderColor, border )
	
	public def isReady() as bool:
		return kernel != 0
	
	public def setKernel(val as byte, bits as byte) as void:
		ig0 = 1f / G0
		val += 1
		data = array[of single](val*val)
		for x in range(0,val):
			for y in range(0,x+1):
				r = Math.Sqrt( x*x+y*y )
				data[y*val+x] = calc.gen() do(qn as single):
					return Bessel.J0(r*qn) * ig0
		for x in range(0,val):
			for y in range(x+1,val):
				data[y*val+x] = data[x*val+y]
		# upload to GPU
		kernel = val
		tKernel.setState(-1,false,false)
		pif = (PixelInternalFormat.Alpha, PixelInternalFormat.R8,
			PixelInternalFormat.R16)[bits>>3]
		GL.TexImage2D( tKernel.target, 0, pif,
			val,val,0,	PixelFormat.Red, PixelType.Float, data)



private class Update( kri.ani.Delta ):
	private final pPrev = kri.shade.par.Texture('prev')
	private final pKern	= kri.shade.par.Texture('kern')
	private final pWave	= kri.shade.par.Texture('wave')
	private final sa	= kri.shade.Smart()
	private final buf	as kri.frame.Buffer
	private cur	as byte = 0
	
	public def constructor(con as Context):
		buf = con.buf
		pKern.Value = con.tKernel
		assert con.isReady()
		# shaders
		con.dict.unit(pPrev,pKern,pWave)
		sa.add('/copy_v','text/wave_f')
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
	
	protected override def onDelta(delta as double) as uint:
		return 0 if	not buf.Width
		GL.Disable( EnableCap.DepthTest )
		if not buf.mask:
			cur = 0
			pPrev.Value = buf.A[1].Tex
			pWave.Value = buf.A[2].Tex
			buf.activate(7)
			kri.rend.Context.ClearColor( Graphics.Color4.Black )
		cur = (cur+1)%3
		# update height
		buf.activate(1<<cur)
		sa.use()
		kri.Ant.Inst.quad.draw()
		pPrev.Value = pWave.Value
		pWave.Value = buf.A[cur].Tex
		#buf.init(0,0)
		return 0



public class Touch( kri.ani.IBase ):
	public final point	= kri.gen.Frame( kri.gen.Point() )
	private	final sa	= kri.shade.Smart()
	private final win	as kri.Window
	private final buf	as kri.frame.Buffer
	private final pPos	= kri.shade.par.Value[of Vector4]('mouse_pos')
	
	public def constructor(kw as kri.Window, con as Context):
		win = kw
		buf = con.buf
		con.dict.var(pPos)
		sa.add('text/touch_v','text/touch_f')
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
	
	def kri.ani.IBase.onFrame(time as double) as uint:
		return 0	if not win.Mouse.Item[Input.MouseButton.Left]
		pPos.Value.Xyz = win.PointerNdc
		GL.Disable( EnableCap.DepthTest )
		buf.activate()
		sa.use()
		GL.PointSize(100f)
		using blend = kri.Blender():
			blend.add()
			point.draw()


public class Draw( kri.rend.Basic ):
	private	final sa	= kri.shade.Smart()
	private final buf	as kri.frame.Buffer
	public	final anim	as Update
	public	lit			as kri.Light	= null
	
	public def constructor(con as Context):
		buf = con.buf
		sa.add('/copy_v','text/draw_f')
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.mask = 0
		buf.init( far.Width, far.Height )
		buf.resizeFrames()
		return true
	
	public override def process(con as kri.rend.Context) as void:
		kri.Ant.Inst.params.activate(lit)
		con.activate()
		sa.use()
		kri.Ant.Inst.quad.draw()
