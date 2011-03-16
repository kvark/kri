namespace support.hair

import OpenTK

#-----------------------------------#
#		Hair baking Tag				#
#-----------------------------------#

public class Tag( kri.ITag, kri.vb.ISource ):
	public final va			= kri.vb.Array()

	[Getter(Data)]
	private final aBase	as kri.vb.Attrib	= kri.vb.Attrib()
	# XYZ: tangent space direction, W: randomness
	public param	= Vector4.UnitZ
	public stamp	as double	= -1f
	public final pixels	as uint

	public def constructor(size as uint):
		pixels = size
		va.bind()
		for i in range(2):
			kri.Help.enrich( aBase, 3, ('prev','base')[i] )
		assert not 'ready'	# initAll?
		#aBase.initAll(size)

	public def makeRoot() as (kri.part.ExtAttrib):
		return (
			kri.part.ExtAttrib( vat:self, dest:'root_prev', source:'prev' ),
			kri.part.ExtAttrib( vat:self, dest:'root_base', source:'base' ))