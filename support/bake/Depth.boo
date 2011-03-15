namespace support.bake.depth

import OpenTK
import OpenTK.Graphics.OpenGL


#-----------------------#
#	Depth baking tag	#

public class Tag( kri.ITag ):
	public final proj	as kri.Projector
	public final tex	= kri.buf.Texture()
	public def constructor():
		proj = kri.Projector()
	public def constructor(pr as kri.Projector):
		proj = pr


#-----------------------#
#	Update render		#

public class Update( kri.rend.Basic ):
	public final bu		= kri.shade.Bundle()
	public final fbo	= kri.buf.Holder(mask:0)
	public final va		= kri.vb.Array()

	public def constructor():
		fbo.at.depth = kri.buf.Texture.Depth(0)
		bu.shader.add('/light/bake_v','/empty_f','/lib/quat_v','/lib/tool_v','/lib/fixed_v')
		bu.link()

	public override def process(con as kri.rend.link.Basic) as void:
		par = kri.Ant.Inst.params
		par.light.data.Value = Vector4(0f,1f,0f,0f)
		con.SetDepth(0f,true)
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of Tag]()
			continue	if not tag
			assert tag.proj
			fbo.at.depth = tag.tex
			fbo.bind()
			con.ClearDepth(1f)
			par.pLit.activate( tag.proj )
			par.modelView.activate( e.node )
			q = kri.Query( QueryTarget.SamplesPassed )
			using q.catch():
				e.render(va,bu,1)
			r = q.result()
			r = 0


#-------------------------------#
#	Particle bounce behavior	#

public class Behavior( kri.part.Behavior ):
	public final pTex	= kri.shade.par.Texture('land')
	public final proj	= kri.lib.par.Project('land')
	
	#note: requires 'tool_v' to be added to the collector
	public def constructor(tag as Tag):
		super('/part/beh/bounce_land')
		pTex.Value = tag.tex
		proj.activate( tag.proj )
	public override def link(d as kri.shade.rep.Dict) as void:	#imp: kri.meta.IBase
		d.unit(pTex)
		(proj as kri.meta.IBase).link(d)
