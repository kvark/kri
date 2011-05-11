namespace support.defer.layer

import kri.shade

public class Fill( kri.rend.Basic ):
	private final	fbo		as kri.buf.Holder
	private final	vao		= kri.vb.Array()
	private final	dInit	= par.DictProxy()
	public	final	buInit	= Bundle()
	public	final	buApply	= Bundle()
	# init
	public def constructor(con as support.defer.Context):
		fbo = con.buf
		buInit.dicts.Add(dInit)
		sa = buInit.shader
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( '/g/layer/make_v', '/g/layer/make_f' )
		sa.fragout('c_diffuse','c_specular','c_normal')
		buInit.link()
	# resize
	public override def setup(pl as kri.buf.Plane) as bool:
		fbo.resize( pl.wid, pl.het )
		return true
	# work	
	public override def process(link as kri.rend.link.Basic) as void:
		fbo.at.depth = link.Depth
		fbo.bind()
		link.SetDepth(0f, false)
		link.ClearColor()
		scene = kri.Scene.Current
		if not scene:	return
		for ent in scene.entities:
			ent.render(vao,buInit)
