namespace support.hair

import OpenTK

#-----------------------------------#
#		Hair baking Tag				#
#-----------------------------------#

public class Tag( kri.ITag ):
	public final va			= kri.vb.Array()
	[Getter(Data)]
	private final aBase	as kri.vb.Attrib	= kri.vb.Attrib()
	# XYZ: tangent space direction, W: randomness
	public param	= Vector4.UnitZ
	public stamp	as double	= -1f
	public final pixels	as uint

	public def constructor(size as uint):
		pixels = size
		for i in range(2):
			kri.Help.enrich( aBase, 3, ('root_prev','root_base')[i] )
		va.bind()
		aBase.initUnit(size)
