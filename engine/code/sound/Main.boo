namespace kri.sound

import OpenTK.Audio.OpenAL

public class Buffer:
	public final id	as uint
	public def constructor(path as string):
		id = AL.GenBuffer()
		#AL.BufferData( id, Sound(path).ReadToEnd() )
	def destructor():
		kri.safeKill({ AL.DeleteBuffer(id) })

public class Source:
	public final id	as uint
	public def constructor(buf as Buffer):
		id = AL.GenSource()
		AL.Source( id, ALSourcei.Buffer, buf.id )
	def destructor():
		kri.safeKill({ AL.DeleteSource(id) })
	public def play() as void:
		AL.SourcePlay(id)
	public def stop() as void:
		AL.SourceStop(id)
