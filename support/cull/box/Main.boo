namespace support.cull.box

###	Entity tag - a sign of bounding box update	###

public class Tag( kri.ITag ):
	public	final	index	as uint
	public	fresh		= false
	private	animated	= false
	private	stamp		as uint	= 0
	
	public def check(bv as kri.vb.Object) as bool:
		if animated != (bv!=null):
			animated = not animated
			stamp = 0
		if stamp == bv.TimeStamp:
			return false
		stamp = bv.TimeStamp
		return true
	
	public def constructor(ind as uint):
		index = ind


###	Read the GPU object and update local bounding boxes	###

public class Update( kri.rend.Basic ):
	private final rez		as (single)
	private final data		as kri.vb.Object
	
	public def constructor(ct as support.cull.Context):
		rez = array[of single]( ct.maxn*4*2 )
		data = ct.bound
		
	public override def process(link as kri.rend.link.Basic) as void:
		scene = kri.Scene.Current
		if not scene:	return
		data.read(rez,0)
		# update local boxes
		for e in scene.entities:
			tag = e.seTag[of Tag]()
			if not (tag and tag.fresh):
				continue
			tag.fresh = false
			i = 2*4 * tag.index
			v0 = OpenTK.Vector3(rez[i+0],rez[i+1],rez[i+2])
			v1 = OpenTK.Vector3(rez[i+4],rez[i+5],rez[i+6])
			e.localBox.center = 0.5f*(v0-v1)
			e.localBox.hsize = -0.5f*(v0+v1)
