namespace support.defer.fill

import kri.buf

#---------	RENDER TO G-BUFFER	--------#

public abstract class Base( kri.rend.tech.Meta ):
	private final buf	as Holder
	# init
	public def constructor(con as support.defer.Context, suf as string):
		meta = kri.load.Meta.LightSet + ('emissive',)
		super('g.make.'+suf, false, ('c_diffuse','c_specular','c_normal'), *meta)
		shade('/g/make')
		shade('/g/norm/'+suf)
		shade(('/light/common_f',))
		dict.attach( con.dict )
		buf = con.buf
	# resize
	public override def setup(pl as kri.buf.Plane) as bool:
		buf.resize( pl.wid, pl.het )
		return true
	# work	
	public override def process(con as kri.rend.link.Basic) as void:
		buf.at.depth = con.Depth
		buf.bind()
		con.SetDepth(0f, false)
		con.ClearColor()
		drawScene()


#---------	RENDER QUATS AND NORMALS	--------#

public class Quat(Base):
	public def constructor(con as support.defer.Context):
		super(con,'quat')
		shade(('/lib/defer_f',))

public class Norm(Base):
	public def constructor(con as support.defer.Context):
		super(con,'norm')
