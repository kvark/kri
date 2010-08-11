namespace demo.water

import OpenTK
import OpenTK.Graphics.OpenGL


private class Water( kri.rend.Basic ):
	private final buf	= kri.frame.Buffer()
	private final pIn	= kri.shade.par.Texture('wave')
	private final sh_wave	= kri.shade.Smart()
	private final sh_draw	= kri.shade.Smart()
	public lit	as kri.Light	= null
	
	public def constructor():
		# buffer attachments
		buf.emit(0, PixelInternalFormat.R8 )	# H0
		buf.emit(1, PixelInternalFormat.R8 )	# H1
		# shaders
		d = kri.shade.rep.Dict()
		d.unit(pIn)
		sh_wave.add('/copy_v','text/wave_f')
		sh_draw.add('/copy_v','text/draw_f')
		for sh in (sh_wave,sh_draw):
			sh.link( kri.Ant.Inst.slotAttributes, d, kri.Ant.Inst.dict )
	public override def setup(far as kri.frame.Array) as bool:
		buf.mask = 0
		buf.init( far.Width, far.Height )
		buf.resizeFrames()
		return true
	public override def process(con as kri.rend.Context) as void:
		kri.Ant.Inst.params.activate(lit)
		con.DepthTest = false
		if not buf.mask:
			buf.activate(1)
			con.ClearColor()
		pIn.Value = buf.A[ buf.mask-1 ].Tex
		# update height
		buf.mask ^= 3
		buf.activate()
		sh_wave.use()
		kri.Ant.Inst.quad.draw()
		# draw to screen
		con.activate()
		sh_draw.use()
		kri.Ant.Inst.quad.draw()



[System.STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		view = kri.ViewScreen()
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.cam.makeOrtho(1f)
		view.scene.lights.Add( kri.Light() )
		
		view.ren = rc = kri.rend.Chain()
		rc.renders.Add( wat = Water() )
		wat.lit = kri.Light()
		wat.lit.node = n = kri.Node('lit')
		n.local.pos = Vector3(5f,3f,10f)
		
		win.Run(30.0,30.0)
