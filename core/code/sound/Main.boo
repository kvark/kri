namespace kri.sound

import OpenTK.Audio.OpenAL


public class Buffer:
	public final handle	as uint
	
	public def constructor():
		handle = AL.GenBuffer()
	def destructor():
		kri.Help.safeKill({ AL.DeleteBuffer(handle) })
	
	public def init(format as ALFormat, data as (byte), rate as int) as void:
		AL.BufferData(handle, format, data, data.Length, rate)


public class Listener( kri.ani.Basic ):
	public	final	node	as kri.Node
	
	public def constructor(n as kri.Node):
		node = n
	
	def kri.ani.IBase.onFrame(time as double) as uint:
		pos = node.World.pos
		AL.Listener( ALListener3f.Position, pos )
		return 0