﻿namespace support.cull

public class HierZ( kri.rend.Basic ):
	public final	fbo		= kri.buf.Holder(mask:0)
	public final	buDown	= kri.shade.Bundle()
	public final	pTex	= kri.shade.par.Texture('input')
	
	public def constructor():
		d = kri.shade.par.Dict()
		d.unit(pTex)
		buDown.dicts.Add(d)
		buDown.shader.add('/copy_v','/cull/down_f')
	public override def process(link as kri.rend.link.Basic) as void:
		fbo.at.depth = t = pTex.Value = link.Depth
		t.setBorder( OpenTK.Graphics.Color4.Black )
		t.setState(0,false,false)
		kri.gen.Texture.createMipmap(fbo,10,buDown)
		t.switchLevel(0)