namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

private def createParticle() as kri.part.Emitter:
	pm = kri.part.Manager( 100000 )
	pm.shaders.Add( kri.shade.Object('./text/born_v') )
	beh = kri.part.beh.Basic('text/beh')
	sl = kri.Ant.Inst.slotParticles
	beh.semantics.Add( kri.vb.attr.Info(
		slot: sl.getForced('pos'), integer:false,
		size:4, type:VertexAttribPointerType.Float ))
	pm.behos.Add(beh)
	
	pLimt = par.Value[of single]('limit')
	pLimt.Value = 2.5f
	pm.dict.var(pLimt)
	return kri.part.Emitter(pm,'mand')


private class Render( kri.rend.part.Simple ):
	pSize = par.Value[of single]('size')
	pBrit = par.Value[of single]('bright')

	public def constructor(pcon as kri.part.Context):
		super(false,true)
		# dict init
		pSize.Value = 5f
		pBrit.Value = 0.025f
		d = kri.shade.rep.Dict()
		d.var(pSize,pBrit)
		# prog init
		sa.add( pcon.sh_draw )
		sa.add( './text/draw_v', './text/draw_f')
		sa.link( kri.Ant.Inst.slotParticles, d, kri.Ant.Inst.dict )



[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant(1,400,300,0):
		view = kri.ViewScreen(16,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		ps = createParticle()
		pcon = kri.part.Context()
		ps.owner.sh_root = pcon.sh_root
		ps.owner.init(pcon)
		ps.allocate()
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.rend.Clear() )
		rlis.Add( Render(pcon) )
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.Particle(ps) )
		ant.Run(30.0,30.0)
