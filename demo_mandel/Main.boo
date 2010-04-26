namespace demo

import System
import OpenTK
import kri.shade

private def createParticle(pc as kri.part.Context) as kri.part.Emitter:
	pm = kri.part.Manager( 100000 )
	pm.makeStandard(pc)
	pm.col_update.extra.Add( kri.shade.Object('./text/born_v') )
	beh = kri.part.beh.Basic('text/beh')
	beh.enrich(2, pc.at_sys)
	beh.enrich(4, pc.at_pos)
	pm.behos.Add(beh)
	
	pLimt = par.Value[of single]('limit')
	pLimt.Value = 2.5f
	pm.dict.var(pLimt)
	pm.init(pc)
	
	ps = kri.part.Emitter(pm,'mand')
	ps.allocate()
	return ps


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
		pcon = kri.part.Context()
		ps = createParticle(pcon)
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.rend.Clear() )
		rlis.Add( Render(pcon) )
		ant.anim = al = kri.ani.Scheduler()
		al.add( kri.ani.Particle(ps) )
		ant.Run(30.0,30.0)
