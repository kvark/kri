namespace support.corp

public class Particle( kri.meta.IBaseMat ):
	kri.INamed.Name as string:
		get: return 'Particle'
	def kri.meta.IBase.link(d as kri.shade.par.Dict) as void:
		return
	def System.ICloneable.Clone() as object:
		return null
