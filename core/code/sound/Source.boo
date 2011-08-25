namespace kri.sound

import OpenTK.Audio.OpenAL

public class Source:
	public final handle		as uint
	
	public def constructor():
		handle = AL.GenSource()
	def destructor():
		kri.Help.safeKill({ AL.DeleteSource(handle) })
	
	public Relative as bool:
		set: AL.Source( handle, ALSourceb.SourceRelative, value )
	public Looping as bool:
		set: AL.Source( handle, ALSourceb.Looping, value )
	public Streaming as bool:
		set:
			type = (ALSourceType.Static, ALSourceType.Streaming)[value]
			AL.Source( handle, ALSourcei.SourceType, cast(int,type) )

	public def init(buf as Buffer) as void:
		AL.Source( handle, ALSourcei.Buffer, buf.handle )
	public def play() as void:
		AL.SourcePlay(handle)
	public def stop() as void:
		AL.SourceStop(handle)