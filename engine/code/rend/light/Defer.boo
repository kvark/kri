namespace kri.rend.light

import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade


#---------	LIGHT PRE-PASS	--------#

public class Defer( kri.rend.Basic ):
	protected final buf		= kri.frame.Buffer()
	protected final sa		= Smart()
	protected final context	as kri.rend.light.Context
	private final texDep	= par.Value[of kri.Texture]('depth')
	private final static	qord	= 1

	public def constructor(lc as kri.rend.light.Context):
		super(false)
		buf.mask = 0
		pif = PixelInternalFormat.Rgb10A2
		for i in range(3):
			buf.A[i].new( pif, TextureTarget.Texture2D )
			buf.mask |= 1<<i
		context = lc
		# baking shader
		sa.add( '/light/defer_v', '/light/defer_f' )
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.fragout('ca','cb','cc')
		d = rep.Dict()
		d.unit(texDep)
		sa.link( kri.Ant.Inst.slotAttributes, d, lc.dict, kri.Ant.Inst.dict )

	private def setLight(l as kri.Light) as bool:
		return false	if l.fov != 0f
		kri.Ant.Inst.params.litView.activate( l.node )
		return true

	public override def setup(far as kri.frame.Array) as bool:
		buf.init( far.Width>>qord, far.Height>>qord )
		return true
		
	public override def process(con as kri.rend.Context) as void:
		con.needDepth(true)
		texDep.Value = buf.A[-1].Tex = con.Depth
		buf.activate()
		con.DepTest = true
		con.ClearColor( Graphics.Color4.Black )
		for l in kri.Scene.current.lights:
			continue	if not setLight(l)
			#draw light geometry
