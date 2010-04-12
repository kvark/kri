namespace demo

import System
import OpenTK
import OpenTK.Graphics.OpenGL
import kri.shade

private def createParticle() as kri.part.Emitter:
	pSize = par.Value[of single]()
	pRoot = par.Value[of single]()
	pBrit = par.Value[of single]()
	pLimt = par.Value[of single]()
	root = 100
	pSize.Value = 10f
	pRoot.Value = 1f * root
	pBrit.Value = 0.05f
	pLimt.Value = 100f
	
	pm = kri.part.Manager( root*root )
	pm.sh_born = kri.shade.Object('/part/born_instant_v')
	beh = kri.part.Behavior('text/beh')
	sl = kri.Ant.Inst.slotParticles
	beh.semantics.Add( kri.vb.attr.Info(
		slot: sl.getForced('pos'), integer:false,
		size:4, type:VertexAttribPointerType.Float ))
	pm.behos.Add(beh)
	
	d = rep.Dict()
	d.add('size',pSize)
	d.add('bright',pBrit)
	pm.dict.add('root',pRoot)
	pm.dict.add('limit',pLimt)
	
	pcon = kri.part.Context()
	pm.init(pcon)
	pe = kri.part.Emitter(pm,'mand',null)
	pe.sa.add( pcon.sh_draw )
	pe.sa.add( './text/draw_v', './text/draw_f')
	pe.sa.link( sl, d, kri.Ant.Inst.dict )	
	pe.init()
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
		rlis.Add( kri.rend.Particles(false) )
		ant.anim = al = kri.ani.Scheduler()
		part = kri.ani.Particle(ps)
		part.lTime = 10000.0
		al.add(part)
		ant.Keyboard.KeyDown += { ps.man.tick(ps) }
		ant.Run(30.0,5.0)
