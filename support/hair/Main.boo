namespace support.hair

import OpenTK

#-----------------------------------#
#		Hair baking Tag				#
#-----------------------------------#

public class Tag( kri.ITag, kri.vb.ISource ):
	public final va			= kri.vb.Array()
	public final at_prev	= kri.Ant.Inst.slotParticles.getForced('prev')
	public final at_base	= kri.Ant.Inst.slotParticles.getForced('base')
	public final ghost_tex	= kri.Ant.inst.slotAttributes.getForced('@tex')
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
			kri.Help.enrich( aBase, 3, (at_prev,at_base)[i] )
		aBase.initAll(size)
