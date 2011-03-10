namespace kri.rend.gauss

import OpenTK
import kri.buf
import kri.shade

#---------	GAUSS FILTER	--------#

public class Simple( kri.rend.Basic ):
	protected	final sa	= Smart()
	protected	final sb	= Smart()
	protected	final texIn	= par.Texture('input')
	public		buf		as Holder	= null

	public def constructor():
		dict = rep.Dict()
		dict.unit(texIn)
		sa.add('/copy_v','/filter/gauss_hor_f')
		sa.link( kri.Ant.Inst.slotAttributes, dict )
		sb.add('/copy_v','/filter/gauss_ver_f')
		sb.link( kri.Ant.Inst.slotAttributes, dict )

	public override def process(con as kri.rend.Context) as void:
		return	if not buf
		assert buf.at.color[0] and buf.at.color[1]
		for i in range(2):
			texIn.Value = buf.at.color[i] as Texture
			buf.mask = 3 ^ (1<<i)
			buf.bind()
			(sa,sb)[i].use()
			kri.Ant.inst.quad.draw()


public class Advanced( kri.rend.Basic ):
	public	final	sa		= Smart()
	public	final	pTex	= par.Texture('input')
	public	final	pDir	= par.Value[of Vector4]('dir')
	public	buf		as Holder = null
	
	public def constructor():
		dict = rep.Dict()
		dict.unit(pTex)
		dict.var(pDir)
		sa.add('/copy_v','/filter/gauss_bi_f')
		sa.link( kri.Ant.Inst.slotAttributes, dict )
	
	public def spawn() as (kri.rend.Basic):
		return ( Axis(self,Vector4.UnitX), Axis(self,Vector4.UnitY) )
	
	public override def process(con as kri.rend.Context) as void:
		return	if not buf
		assert buf.at.color[0] and buf.at.color[1]
		sa.useBare()
		for i in range(2):
			pTex.Value = buf.at.color[i] as Texture
			pDir.Value = (Vector4.UnitX,Vector4.UnitY)[i]
			buf.mask = 3 ^ (1<<i)
			buf.bind()
			Smart.UpdatePar()
			kri.Ant.inst.quad.draw()


public class Axis( kri.rend.Basic ):
	public final parent	as Advanced
	public final dir	as Vector4
	
	public def constructor(par as Advanced, axis as Vector4):
		super(true)
		parent = par
		dir = axis
	
	public override def process(con as kri.rend.Context) as void:
		parent.pTex.Value = con.Input
		parent.pDir.Value = dir
		con.activate(true)
		parent.sa.use()
		kri.Ant.inst.quad.draw()
