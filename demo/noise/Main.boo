namespace demo.noise

import OpenTK


public class Simplex( kri.rend.Basic ):
	public final pMouse = kri.shade.par.Value[of Vector4]('mouse_coord')
	public final sa = kri.shade.Smart()
	private kwid	as single	= 1f
	private khet	as single	= 1f

	public def constructor(noise as kri.kit.gen.Noise):
		super(false)
		# init textures
		if noise:	noise.generate(8)
		else:	noise = kri.kit.gen.Noise(8)
		# init shader
		sa.add('/copy_v','text/main_f')
		sa.add( noise.sh_simplex, noise.sh_turbo )
		noise.dict.var( pMouse )
		sa.link( kri.Ant.Inst.slotAttributes, noise.dict, kri.Ant.Inst.dict )
		# init mouse
		kri.Ant.Inst.Mouse.Move += def():
			pMouse.Value.Xyz = kri.Ant.Inst.PointerNdc
	
	public override def setup(far as kri.frame.Array) as bool:
		kwid = 1f / far.Width
		khet = 1f / far.Height
		return true

	public override def process(con as kri.rend.Context) as void:
		con.activate()
		sa.use()
		kri.Ant.Inst.emitQuad()



[System.STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen(0,8,0)
		view.ren = Simplex(null)
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		ant.Run(30.0)
