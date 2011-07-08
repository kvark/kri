namespace support.cull.box

###	Entity tag - a sign of bounding box update	###

public class Tag( kri.ITag ):
	public	fresh		= false
	private	index		as int	= -1
	private	animated	= false
	private	stamp		as uint	= 0
	
	public Index	as int:
		get: return index
		set:
			assert index<0
			index = value
	
	public def check(bv as kri.vb.Object) as bool:
		if animated != (bv!=null):
			animated = not animated
			stamp = 0
		if stamp == bv.TimeStamp:
			return false
		stamp = bv.TimeStamp
		return true
