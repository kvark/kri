namespace kri.lib.par.proj

import System
import OpenTK
import kri.shade
import kri.meta

#todo: create a linked version

# basic projector settings
public final class Shared( IBase ):
	[getter(Name)]
	private final name	as string
	public final data	as par.Value[of Vector4]
	public final range	as par.Value[of Vector4]
	
	public def constructor(s as string):
		name = s
		data	= par.Value[of Vector4]('proj_'+s)
		range	= par.Value[of Vector4]('range_'+s)
	
	public def activate(p as kri.Projector) as void:
		div = 1f / (p.rangeIn - p.rangeOut)
		dad = div *(p.rangeIn + p.rangeOut)
		tn = 1f
		if p.fov > 0f:
			tn = System.Math.Tan(p.fov)
			data.Value = Vector4(1f / tn, p.aspect / tn, dad,
				2f*div*(p.rangeIn*p.rangeOut) )
		else:	# the last parameter sign shows orthogonality
			data.Value = Vector4(-p.fov, -p.fov * p.aspect, 2f*div, -dad)
		range.Value = Vector4(p.rangeIn, p.rangeOut, div, tn)
	
	def IBase.link(d as par.Dict) as void:
		d.var(data,range)
