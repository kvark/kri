namespace kri.shade

import System.Collections.Generic

#-------------------------------#
#	SHADER LINKER CHACHE		#
#-------------------------------#

public class Linker:
	private final condict	as (rep.Dict)
	public final samap = Dictionary[of string,Bundle]()
	public onLink	as callable(Mega)	= null
	
	public def constructor(*cad as (rep.Dict)):
		condict = cad
	
	public def link(sl as Object*, *dc as (rep.Dict)) as Bundle:
		key = join( (x.handle.ToString() for x in sl), ',' )
		bu as Bundle = null
		if samap.TryGetValue(key,bu):
			bu = Bundle(bu)
			bu.dicts.AddRange(condict)
			bu.dicts.AddRange(dc)
			bu.fillParams()
			# yes, we will just fill the parameters for this program ID again
			# it's not obvious, but texture units will be assigned to the old values,
			# because the meta-data sets already matched (kri.load.meta.MakeTexCoords)
		else:
			bu = Bundle()
			bu.shader.add( *List[of Object](sl).ToArray() )
			bu.dicts.AddRange(condict)
			bu.dicts.AddRange(dc)
			if onLink:
				onLink( bu.shader )
			samap.Add(key,bu)
		return bu
