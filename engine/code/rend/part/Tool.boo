namespace kri.rend.part

public class Standard( Meta ):
	public def constructor(pc as kri.part.Context):
		super('part.std', 'halo','diffuse')
		shobs.Add( pc.sh_draw )
		shade('/part/draw/load')
		dTest,bAdd = true,false
