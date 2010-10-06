namespace support.corp.child

import System
import OpenTK


#---	particle children	---#
public class Meta( kri.meta.Advanced ):
	public num	as ushort	= 0
	private final data	= kri.shade.par.Value[of Vector4]('part_child')
	portal Data	as Vector4	= data.Value
	
	def ICloneable.Clone() as object:
		return copyTo( Meta( num:num, Data:Data ))
	def kri.meta.IBase.link(d as kri.shade.rep.Dict) as void:
		d.var(data)
