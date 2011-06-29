namespace support.cull

public class HierZ( kri.rend.Basic ):
	public final	fbo		= kri.buf.Holder(mask:0)
	public final	buDown	= kri.shade.Bundle()
	public final	pTex	= kri.shade.par.Texture('input')
	
	public def constructor():
		d = kri.shade.par.Dict()
		d.var(pTex)
		buDown.dicts.Add(d)
		buDown.shader.add('/copy_v','/cull/down_f')
	public override def process(link as kri.rend.link.Basic) as void:
		fbo.at.depth = t = link.Depth
		t.filt(false,false)
		kri.gen.Texture.createMipmap(fbo,10,buDown)
		t.switchLevel(0)