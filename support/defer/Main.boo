namespace support.defer

import OpenTK.Graphics.OpenGL
import kri.buf
import kri.shade

public class Context:
	public final buf		= Holder()
	public final dict		= rep.Dict()
	public final texDepth	= par.Texture('depth')
	public final sh_diff	= Object.Load('/mod/lambert_f')
	public final sh_spec	= Object.Load('/mod/phong_f')
	public final sh_apply	= Object.Load('/g/apply_f')
	
	public def constructor():
		dict.unit(texDepth)
		# diffuse, specular, world space normal
		for i in range(3):
			pt = par.Texture('g'+i)
			buf.at.color[i] = pt.Value =  Texture( samples:3,
				intFormat:PixelInternalFormat.Rgb10A2 )
			pt.Value.filt(false,false)
			dict.unit(pt)


#---------	RENDER TO G-BUFFER	--------#

public class Fill( kri.rend.tech.Meta ):
	private final buf	as Holder
	# init
	public def constructor(con as Context):
		super('g.make', false, ('c_diffuse','c_specular','c_normal'), *kri.load.Meta.LightSet)
		shade(('/g/make_v','/g/make_f','/light/common_f'))
		buf = con.buf
	# resize
	public override def setup(pl as kri.buf.Plane) as bool:
		buf.resize( pl.wid, pl.het )
		return true
	# work	
	public override def process(con as kri.rend.Context) as void:
		con.needDepth(false)
		buf.at.depth = con.Depth
		buf.bind()
		con.SetDepth(0f, false)
		con.ClearColor()
		drawScene()
