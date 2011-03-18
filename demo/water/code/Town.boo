namespace demo.water

import System
import kri.buf

private class Town( kri.rend.Basic ):
	private	final fbo	= Holder( mask:1 )
	private	final bu	= kri.shade.Bundle()
	public	final con	= kri.gen.Noise(8)
	
	public Result:
		get:
			active = true
			return fbo.at.color[0]
	
	public def constructor():
		bu.shader.add( con.sh_simplex, con.sh_turbo )
		bu.shader.add( '/copy_v', 'text/town_f' )
		bu.dicts.Add( con.dict )
		fbo.at.color[0] = Texture.Color(0)
	
	public override def setup(pl as kri.buf.Plane) as bool:
		active = true
		fbo.resize( pl.wid, pl.het )
		return true
	
	public override def process(con as kri.rend.link.Basic) as void:
		active = false
		con.DepthTest = false
		fbo.bind()
		kri.Ant.Inst.quad.draw(bu)
