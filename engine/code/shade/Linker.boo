namespace kri.shade

import System.Collections.Generic

#-------------------------------#
#	SHADER LINKER CHACHE		#
#-------------------------------#

public class Linker:
	private final aslot		as kri.lib.Slot
	private final condict	as (rep.Dict)
	public final samap = Dictionary[of string,Smart]()
	public onLink	as callable(Smart)	= null
	
	public def constructor(ats as kri.lib.Slot, *cad as (rep.Dict)):
		aslot = ats
		condict = cad
	
	public def link(sl as Object*, *dc as (rep.Dict)) as Smart:
		key = join( (x.handle.ToString() for x in sl), ',' )
		sa as Smart = null
		if samap.TryGetValue(key,sa):
			sa = Smart(sa)
			sa.fillPar(false,*dc)
			# yes, we will just fill the parameters for this program ID again
			# it's not obvious, but texture units will be assigned to the old values,
			# because the meta-data sets already matched (kri.load.meta.MakeTexCoords)
		else:
			sa = Smart()
			sa.add( *List[of Object](sl).ToArray() )
			onLink(sa)	if onLink
			sa.link( aslot, *(condict+dc) )
			samap.Add(key,sa)
		return sa
