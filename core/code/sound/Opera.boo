namespace kri.sound

import System.Collections.Generic

public class Opera(System.IDisposable):
	[getter(Inst)]
	private static inst	as Opera = null		# Singleton

	public	final	context	as OpenTK.Audio.AudioContext
	public	final	caps	= Capabilities()
	public	final	sources	= List[of Source]()
	public	listener	as kri.Node	= null
	
	public def constructor(device as string):
		if string.IsNullOrEmpty(device):
			context = OpenTK.Audio.AudioContext()
		else:
			context = OpenTK.Audio.AudioContext(device)
		inst = self
	
	def System.IDisposable.Dispose() as void:
		inst = null
	
	public def update() as void:
		context.CheckErrors()
		spa = kri.Node.SafeWorld(listener)
		Listener.Position = spa.pos
		for src in sources:
			spa = kri.Node.SafeWorld(src.node)
			src.Position = spa.pos
