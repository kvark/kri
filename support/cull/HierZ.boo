namespace support.cull.hier

import OpenTK.Graphics.OpenGL

public class Fill( kri.rend.Basic ):
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
		t.setBorder( OpenTK.Graphics.Color4.White )
		t.shadow(false)
		t.setState(0,false,false)
		kri.gen.Texture.createMipmap(fbo,10,buDown)
		t.switchLevel(0)



public class Apply( kri.rend.Basic ):
	public	final	bu		= kri.shade.Bundle()
	public	final	pTex	= kri.shade.par.Texture('input')
	private	final	tf		= kri.TransFeedback(1)
	private	final	mesh	= kri.Mesh( BeginMode.Points )
	private	final	dest	= kri.vb.Object()
	private	final	va		= kri.vb.Array()
	private	final	spatial	= kri.vb.Attrib()
	private final	rez		as (int)
	private final	model 	as (kri.Spatial)
	
	public def constructor(box as support.cull.box.Update):
		d = kri.shade.par.Dict()
		d.unit(pTex)
		bu.dicts.Add(d)
		bu.shader.add( '/cull/check_v', '/lib/quat_v', '/lib/tool_v' )
		bu.shader.feedback(true,'to_visible')
		mesh.nVert = box.maxn
		mesh.vbo.Add( box.data )
		mesh.vbo.Add( spatial )
		rez = array[of int]( box.maxn )
		model = array[of kri.Spatial]( box.maxn )
		dest.init( box.maxn * 4 )
		kri.Help.enrich(spatial, 4, 'pos','rot')
	
	public override def process(link as kri.rend.link.Basic) as void:
		link.DepthTest = false
		pTex.Value = t = link.Depth
		if not t.MipMapped:
			kri.lib.Journal.Log('HierZ: mip chain has not been constructed')
			return
		scene = kri.Scene.Current
		if not scene:	return
		# pass spatial info array
		for ent in scene.entities:
			tag = ent.seTag[of support.cull.box.Tag]()
			if not tag: continue
			model[tag.index] = kri.Node.SafeWorld( ent.node )
		spatial.init(model,true)
		# perform culling
		tf.Bind(dest)
		using kri.Discarder():
			mesh.render(va,bu,tf)
		# store the result
		cam = kri.Camera.Current
		dest.read(rez,0)
		for ent in scene.entities:
			tag = ent.seTag[of support.cull.box.Tag]()
			if not tag: continue
			vis = rez[tag.index] != 0
			ent.frameVisible[cam] = vis
