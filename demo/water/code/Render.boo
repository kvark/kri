namespace demo.water

import System
import OpenTK
import OpenTK.Graphics.OpenGL


private class Context:
	public final buf	= kri.frame.Buffer()
	public final tKernel	= kri.Texture( TextureTarget.Texture1D )
	public final dict		= kri.shade.rep.Dict()
	public final calc	= Calculator(10000,0.001f,1f)
	private final G0	as single	= calc.gen({x| return 1f})
	public final kernel	as byte
	
	public def constructor(ord as byte):
		# buffer attachments
		border = (of single: 0f,0f,0f,0f)
		for i in range(2):
			t = buf.emit(i, PixelInternalFormat.Rg16f )
			t.setState(-1,false,false)
			GL.TexParameter( t.target, TextureParameterName.TextureBorderColor, border )
		kernel = ord
		setKernel(ord)
	
	private def setKernel(order as byte) as void:
		ig0 = 1f / G0
		data = array[of single]( 2f*order*order+1 )
		for r2 in range(data.Length):
			r = Math.Sqrt(r2)
			data[r2] = calc.gen() do(qn as single):
				return Bessel.J0(r*qn) * ig0
		# upload to GPU
		tKernel.setState(-1,false,false)
		GL.TexImage1D( tKernel.target, 0, PixelInternalFormat.R16f,
			data.Length,0,	PixelFormat.Red, PixelType.Float, data)



private class Update( kri.ani.Delta ):
	private final pKern	= kri.shade.par.Texture('kern')
	private final pWave	= kri.shade.par.Texture('wave')
	private final pCon	= kri.shade.par.Value[of Vector4]('wave_con')
	private final sa	= kri.shade.Smart()
	private final buf	as kri.frame.Buffer
	private final kb	as Input.KeyboardDevice
	
	public def constructor(con as Context, win as kri.Window):
		buf = con.buf
		kb = win.Keyboard
		pKern.Value = con.tKernel
		pCon.Value = Vector4( 0.3f, 9.81f, 0f,0f )
		# shaders
		con.dict.unit(pKern,pWave)
		con.dict.var(pCon)
		sa.add('/copy_v','text/wave_f')
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
	
	protected override def onDelta(delta as double) as uint:
		return 0 if	not buf.Width
		if kb[Input.Key.Q]:	pCon.Value.X -= 0.1f
		if kb[Input.Key.W]:	pCon.Value.X += 0.1f
		if kb[Input.Key.A]:	pCon.Value.Y -= 1.0f
		if kb[Input.Key.S]:	pCon.Value.Y += 1.0f
		GL.Disable( EnableCap.DepthTest )
		if not buf.mask:
			buf.activate(1)
			kri.rend.Context.ClearColor( Graphics.Color4.Black )
		# update height
		pWave.Value = buf.A[buf.mask-1].Tex
		buf.mask ^= 3
		buf.activate()
		sa.use()
		kri.Ant.Inst.quad.draw()
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
	public final pTownTex	= kri.shade.par.Texture('town')
	public final pTownPos	= kri.shade.par.Value[of Vector4]('town_pos')
	public	lit			as kri.Light	= null
	
	public def constructor(con as Context):
		con.dict.unit(pTownTex)
		con.dict.var(pTownPos)
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
