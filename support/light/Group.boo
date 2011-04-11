namespace support.light.group

import support.light


public class Forward:
	public final con	as Context
	public final list	= List[of kri.rend.Basic]()
	
	public def constructor(quality as byte):
		con = Context(0,quality)
		list.Add( Fill(con) )
		list.Add( Apply(con) )
		list.Add( omni.Fill(con) )
		list.Add( omni.Apply(false) )
	
	public def enable(on as bool) as void:
		for r in list:
			r.active = on