namespace kri.rend.defer

import OpenTK.Graphics.OpenGL
import kri.shade


public class Context:
	public final tex = kri.Texture( TextureTarget.Texture2DArray )
	public final gbuf = par.Value[of kri.Texture]('gbuf')
	public final sh_diff	= Object.Load('/mod/lambert_f')
	public final sh_spec	= Object.Load('/mod/phong_f')
	public final sh_apply	= Object.Load('/g/apply_f')
	
	public def constructor():
		gbuf.Value = tex


#---------	RENDER TO G-BUFFER	--------#

public class Fill( kri.rend.tech.Meta ):
	public final buf		= kri.frame.Buffer(0)
	# init
	public def constructor(con as Context):
		super('g.make', false, ('c_diffuse','c_specular','c_normal'), *kri.load.Meta.LightSet)
		shade(('/g/make_v','/g/make_f','/light/common_f'))
		buf.A[0].layer(con.tex,0) # diffuse
		buf.A[1].layer(con.tex,1) # specular
		buf.A[2].layer(con.tex,2) # world space normal
		buf.mask = 0x7
	# resize
	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width, far.Height )
		buf.A[0].Tex.bind()
		fm = kri.Texture.AskFormat( kri.Texture.Class.Color, 8 )
		fm = PixelInternalFormat.Rgb10A2
		kri.Texture.Init( fm, far.Width, far.Height, 3 )
		kri.Texture.Filter(false,false)
		return true
	# work	
	public override def process(con as kri.rend.Context) as void:
		con.needDepth(false)
		buf.A[-1].Tex = con.Depth
		buf.activate()
		con.SetDepth(0f, false)
		con.ClearColor()
		drawScene()
