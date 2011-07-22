namespace support.asm


public class DrawSimple( kri.rend.Basic ):
	public	final	bu	= kri.shade.Bundle()
	public	final	va	= kri.vb.Array()
	public	final	q	= kri.Query()
	
	public def constructor():
		bu.shader.add('/asm/draw/simple_v','/white_f','/lib/quat_v','/lib/tool_v')
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.activate( link.Target.Same, 0f, true )
		link.ClearDepth(1.0)
		link.ClearColor()
		Scene.Current.mesh.render(va,bu,null)
