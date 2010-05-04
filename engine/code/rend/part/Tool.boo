namespace kri.rend.part

public class Standard( Meta ):
	public def constructor(pc as kri.part.Context):
		super('part.std', false, 'halo','diffuse')
		shobs.Add( pc.sh_draw )
		shade('/part/draw/load')
		bAdd = false
	public override def process(con as kri.rend.Context) as void:
		con.activate(true,0f,false)
		drawScene()
