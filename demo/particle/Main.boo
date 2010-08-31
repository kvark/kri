namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL

class ProjTag( kri.ITag ):
	public final proj	as kri.Projector
	public final tex	= kri.Texture( TextureTarget.Texture2D )
	public dSize		= kri.frame.DirtyHolder[of uint](0)
	public Size as uint:
		get: return dSize.Value
		set: dSize.Value = value
	public def constructor():
		proj = kri.Projector()
	public def constructor(pr as kri.Projector):
		proj = pr


class ProjUpdate( kri.rend.Basic ):
	public final sa		= kri.shade.Smart()
	public final buf	= kri.frame.Buffer()
	public final va		= kri.vb.Array()
	public def constructor():
		super(false)
		buf.A[-1].Format = PixelInternalFormat.DepthComponent
		buf.mask = 0
		sa.add('/light/bake_v','/empty_f','/lib/quat_v','/lib/tool_v','/lib/fixed_v')
		sa.link(kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict)
	public override def process(con as kri.rend.Context) as void:
		par = kri.Ant.Inst.params
		par.light.data.Value = Vector4(0f,1f,0f,0f)
		con.SetDepth(0f,true)
		va.bind()
		for e in kri.Scene.Current.entities:
			tag = e.seTag[of ProjTag]()
			continue	if not tag
			assert tag.proj
			buf.init( tag.Size, tag.Size )
			buf.A[-1].Tex = tag.tex
			if tag.dSize.Dirty:
				buf.resizeFrames()
				tag.dSize.clean()
			buf.activate()
			con.ClearDepth(1f)
			par.pLit.activate( tag.proj )
			par.modelView.activate( e.node )
			sa.use()
			e.enable(true, (kri.Ant.Inst.attribs.vertex,))
			q = kri.Query( QueryTarget.SamplesPassed )
			using q.catch():
				e.mesh.draw(1)
			r = q.result()
			r = 0


class Behavior( kri.part.Behavior ):
	public final pTex	= kri.shade.par.Texture('land')
	public final proj	= kri.lib.par.Project('land')
	public def constructor(tag as ProjTag):
		super('text/beh_land')
		pTex.Value = tag.tex
		proj.activate( tag.proj )
	public override def link(d as kri.shade.rep.Dict) as void:	#imp: kri.meta.IBase
		d.unit(pTex)
		(proj as kri.meta.IBase).link(d)


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		win.core.extensions.Add( cex = support.corp.Extra() )
		view = kri.ViewScreen()
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		ln = kri.load.Native()
		at = ln.read('res/test_particles.scene')
		view.scene = at.scene
		view.cam = at.scene.cameras[0]
		
		land = at.scene.entities[0]
		land.tags.Add( pTag = ProjTag() )
		pTag.Size = 256
		pro = pTag.proj
		pro.node = kri.Node('proj')
		pro.node.local.pos.Z = 5f
		pro.makeOrtho( 2f * land.node.local.scale )
		pro.setRanges( 1f, 6f )
		
		man = at.scene.particles[0].owner
		man.behos.Add( Behavior(pTag) )
		man.col_update.extra.Add( kri.shade.Object.Load('/lib/tool_v') )
		man.init( cex.pcon )
		
		rlis.Add( support.bake.Update() )
		rlis.Add( rem = kri.rend.Emission(fillDepth:true) )
		rem.pBase.Value = Graphics.Color4.Black
		rlis.Add( ProjUpdate() )
		
		rlis.Add( kri.rend.light.omni.Apply(false) )
		rlis.Add( stand = kri.rend.part.Standard(cex.pcon) )
		stand.bAdd = 1f
		rlis.Add( kri.rend.FilterCopy() )
		#pTex = kri.shade.par.UnitProxy({ return pTag.tex })
		#rlis.Add( kri.rend.debug.Map(false,false,-1,pTex) )
		
		win.core.anim = al = kri.ani.Scheduler()
		#al.add( kri.ani.ControlMouse(ent.node,0.003f) )
		al.add( kri.ani.Particle(at.scene.particles[0]) )
		win.Run(30.0,30.0)
