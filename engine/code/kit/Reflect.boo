namespace kri.kit.reflect

import OpenTK.Graphics.OpenGL
import kri.shade


public class Tag( kri.ITag ):
	public final pTex	as par.ValuePure[of kri.Texture]
	public counter	as int		= 0
	public depth	as byte		= 0
	public size		as ushort	= 256
	public zoom		as single	= 1f
	public rangeIn	as single	= 1f
	public rangeOut	as single	= 100f
	public cubic	as bool		= true
	public def constructor(pt as par.ValuePure[of kri.Texture]):
		pTex = pt


public class Update( kri.rend.Basic ):
	private final buPlane	= kri.frame.Buffer(0, TextureTarget.Texture2D )
	private final buCube	= kri.frame.Buffer(0, TextureTarget.TextureCubeMap )
	
	public def constructor():
		buPlane	.emitAuto(-1,0)
		buCube	.emitAuto(-1,0)
	
	private def drawScene() as void:
		pass	# draw everything!
	
	public override def process(con as kri.rend.Context) as void:
		for ent in kri.Scene.Current.entities:
			tag = ent.seTag[of Tag]()
			continue	if not tag or not tag.counter
			kri.Ant.Inst.params.camView.activate( ent.node )
			buf = (buPlane,buCube)[tag.cubic]
			tag.counter -= 1
			if not tag.pTex.Value:
				tag.pTex.Value = buf.emitAuto(0,8)
			else: buf.A[0].Tex = tag.pTex.Value
			buf.activate()
			con.ClearDepth(1f)
			con.ClearColor()
			drawScene()
