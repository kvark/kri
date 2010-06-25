namespace kri.sound

import OpenTK.Audio.OpenAL


public class Buffer:
	public final id	as uint
	public def constructor():
		id = AL.GenBuffer()
	public def init(format as ALFormat, data as (byte), rate as int) as void:
		AL.BufferData(id, format, data, data.Length, rate)
	def destructor():
		kri.Help.safeKill({ AL.DeleteBuffer(id) })


public class Source:
	public final buf	as Buffer
	public final id		as uint
	
	public def constructor(buffer as Buffer):
		id = AL.GenSource()
		buf = buffer
		AL.Source( id, ALSourcei.Buffer, buf.id )
	public def constructor(src as Source):
		id = AL.GenSource()
		buf = src.buf
		AL.Source( id, ALSourcei.Buffer, buf.id )
	def destructor():
		kri.Help.safeKill({ AL.DeleteSource(id) })
	
	public def play() as void:
		AL.SourcePlay(id)
	public def stop() as void:
		AL.SourceStop(id)
