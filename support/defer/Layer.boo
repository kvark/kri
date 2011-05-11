namespace support.defer.layer

import kri.shade

public class Fill( kri.rend.tech.General ):
	private final	fbo		as kri.buf.Holder
	private	mesh	as kri.Mesh		= null
	private	dict	as kri.vb.Dict	= null

	# init
	public def constructor(con as support.defer.Context):
		super('g.layer.fill')
		fbo = con.buf

	# construct
	public override def construct(mat as kri.Material) as Bundle:
		bu = Bundle()
		bu.dicts.Add( mat.dict )
		sa = bu.shader
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( '/g/layer/make_v', '/g/layer/make_f' )
		sa.fragout('c_diffuse','c_specular','c_normal')
		return bu
	
	# draw
	protected override def onPass(va as kri.vb.Array, tm as kri.TagMat, bu as Bundle) as void:
		mesh.render( va, bu, dict, tm.off, tm.num, 1, null )

	# resize
	public override def setup(pl as kri.buf.Plane) as bool:
		fbo.resize( pl.wid, pl.het )
		return super(pl)

	# work	
	public override def process(link as kri.rend.link.Basic) as void:
		fbo.at.depth = link.Depth
		fbo.bind()
		link.SetDepth(0f, false)
		link.ClearColor()
		scene = kri.Scene.Current
		if not scene:	return
		for e in scene.entities:
			kri.Ant.Inst.params.activate(e)
			dict = e.CombinedAttribs
			mesh = e.mesh
			addObject(e)
