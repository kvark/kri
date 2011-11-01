namespace support.corp


public class Particle( kri.meta.IBaseMat ):

	kri.INamed.Name as string:
		get: return 'Particle'
	def kri.meta.IBase.link(d as kri.shade.par.Dict) as void:
		return
	def System.ICloneable.Clone() as object:
		return null

	public	material	as kri.Material	= null
	public	source		as kri.Entity	= null
	public	filled		as bool			= false
	public	onUpdate	as System.Func[of kri.Entity,bool]	= null
	
	public	final owner	as kri.part.Manager	= null
	public	final name	as string			= null
	public	final entries	= kri.vb.Dict()
