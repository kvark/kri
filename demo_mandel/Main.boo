namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

private def createParticle() as kri.part.Emitter:
	pSize = par.Value[of single]('size')
	pBrit = par.Value[of single]('bright')
	pLimt = par.Value[of single]('limit')
	pSize.Value = 5f
	pBrit.Value = 0.025f
	pLimt.Value = 2.5f
	
	pm = kri.part.Manager( 100000 )
	pm.sh_born = kri.shade.Object('./text/born_v')
	beh = kri.part.beh.Basic('text/beh')
	sl = kri.Ant.Inst.slotParticles
	beh.semantics.Add( kri.vb.attr.Info(
		slot: sl.getForced('pos'), integer:false,
		size:4, type:VertexAttribPointerType.Float ))
	pm.behos.Add(beh)
	
	d = rep.Dict()
	d.var(pSize,pBrit)
	pm.dict.var(pLimt)
	
	pcon = kri.part.Context()
	pm.init(pcon)
	pe = kri.part.Emitter(pm,'mand')
	pe.sa = Smart()
	pe.sa.add( pcon.sh_draw )
	pe.sa.add( './text/draw_v', './text/draw_f')
	pe.sa.link( sl, d, kri.Ant.Inst.dict )	
	return pe


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
		view.scene.particles.Add(ps)
		
		rlis.Add( kri.rend.Clear() )
		rlis.Add( kri.rend.part.Basic(false,true) )
		ant.anim = al = kri.ani.Scheduler()
		part = kri.ani.Particle(ps)
		al.add(part)
		ant.Keyboard.KeyDown += { ps.man.tick(ps) }
		ant.Run(30.0,30.0)
