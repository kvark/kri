namespace demo.water

import System
import kri.buf

private class Town( kri.rend.Basic ):
	private final buf	= Holder( mask:1 )
	private final sa	= kri.shade.Smart()
	public final con	= kri.gen.Noise(8)
	
	public Result:
		get:
			active = true
			return buf.at.color[0]
	
	public def constructor():
		super(false)
		sa.add( con.sh_simplex, con.sh_turbo )
		sa.add( '/copy_v', 'text/town_f' )
		sa.link( kri.Ant.Inst.slotAttributes, con.dict, kri.Ant.Inst.dict )
		buf.at.color[0] = Texture.Color(0)
	
	public override def setup(pl as kri.buf.Plane) as bool:
		active = true
		buf.resize( pl.wid, pl.het )
		return true
	
	public override def process(con as kri.rend.link.Basic) as void:
		active = false
		con.DepthTest = false
		buf.bind()
		sa.use()
		kri.Ant.Inst.quad.draw()
