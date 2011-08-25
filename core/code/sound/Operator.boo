namespace kri.sound

import System.Collections.Generic

public class Operator:
	public final sources	= List[of Source]()
	public	listener	as kri.Node	= null
	
	public def update() as void:
		Listener.Position = listener.World.pos
		for src in sources:
			spa = kri.Node.SafeWorld(src.node)
			src.Position = spa.pos
