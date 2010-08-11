namespace demo.water

import System
import OpenTK.Graphics.OpenGL

private class Water( kri.rend.Basic ):
	private final buf	= kri.frame.Buffer()
	private final pKern	= kri.shade.par.Texture('kern')
	private final pWave	= kri.shade.par.Texture('wave')
	private final sh_wave	= kri.shade.Smart()
	private final sh_draw	= kri.shade.Smart()
	public lit	as kri.Light	= null
	private kernel	as byte		= 0
	public final calc	= Calculator(10000,0.001f,1f)
	private final G0	as single	= calc.gen({x| return 1f})
	
	public def constructor():
		pKern.Value = kri.Texture( TextureTarget.Texture2D )
		# buffer attachments
		for i in range(2):
			t = buf.emit(i, PixelInternalFormat.R8 )
			t.setState(false,false,false)
		# shaders
		d = kri.shade.rep.Dict()
		d.unit(pKern,pWave)
		sh_wave.add('/copy_v','text/wave_f')
		sh_draw.add('/copy_v','text/draw_f')
		for sh in (sh_wave,sh_draw):
			sh.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
			
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
		pKern.Value.setState(false,false,false)
		pif = (PixelInternalFormat.Alpha, PixelInternalFormat.R8,
			PixelInternalFormat.R16)[bits>>3]
		GL.TexImage2D( pKern.Value.target, 0, pif,
			val,val,0,	PixelFormat.Red, PixelType.Float, data)
	
	public override def setup(far as kri.frame.Array) as bool:
		buf.mask = 0
		buf.init( far.Width, far.Height )
		buf.resizeFrames()
		return true
	
	public override def process(con as kri.rend.Context) as void:
		assert kernel
		kri.Ant.Inst.params.activate(lit)
		con.DepthTest = false
		if not buf.mask:
			buf.activate(1)
			con.ClearColor()
		pWave.Value = buf.A[ buf.mask-1 ].Tex
		# update height
		buf.mask ^= 3
		buf.activate()
		sh_wave.use()
		kri.Ant.Inst.quad.draw()
		# draw to screen
		con.activate()
		sh_draw.use()
		kri.Ant.Inst.quad.draw()
