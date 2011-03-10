namespace kri.rend.part

public class Standard( Meta ):
	public def constructor(pc as kri.part.Context):
		super('part.std', false, 'halo','diffuse')
		shobs.Add( pc.sh_draw )
		shade('/part/draw/load')
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate( con.Target.Same, 0f, false )
		drawScene()
