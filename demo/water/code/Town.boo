namespace demo.water

import System

private class Town( kri.rend.Basic ):
	private final buf	= kri.frame.Buffer()
	private final sa	= kri.shade.Smart()
	public final con	= kri.gen.Noise(8)
	
	public Result:
		get:
			active = true
			return buf.A[0].Tex
	
	public def constructor():
		super(false)
		sa.add( con.sh_simplex, con.sh_turbo )
		sa.add( '/copy_v', 'text/town_f' )
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
		buf.emit(0, kri.Texture.Class.Color, 8)
	
	public override def setup(far as kri.frame.Array) as bool:
		active = true
		buf.init( far.Width, far.Height )
		buf.resizeFrames()
		return true
	
	public override def process(con as kri.rend.Context) as void:
		active = false
		con.DepthTest = false
		buf.activate(1)
		sa.use()
		kri.Ant.Inst.quad.draw()
