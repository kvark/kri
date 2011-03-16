namespace demo.mandel

import OpenTK
import kri.shade


private def createParticle(pc as kri.part.Context) as kri.part.Emitter:
	pm = kri.part.Manager( 2000 )
	pm.makeStandard(pc)
	pm.col_init.extra.Add( pc.sh_tool )
	pm.col_update.root = Object.Load('text/root_v')
	pm.col_update.extra.Add( Object.Load('text/born_v') )
	beh = kri.part.Behavior('text/beh')
	kri.Help.enrich(beh,4,'pos')
	kri.Help.enrich(beh,1,'sys')
	pm.behos.Add(beh)
	
	pLimt = par.Value[of single]('limit')
	pLimt.Value = 2.5f
	pm.dict.var(pLimt)
	pm.init(pc)
	
	return kri.part.Emitter(pm,'mand')


private class Render( kri.rend.part.Simple ):
	pSize = par.Value[of single]('size')
	pBrit = par.Value[of single]('bright')

	public def constructor(pcon as kri.part.Context):
		super()
		dTest,bAdd = false,true
		# dict init
		pSize.Value = 5f
		pBrit.Value = 0.002f
		d = rep.Dict()
		d.var(pSize,pBrit)
		# prog init
		bu.shader.add( 'text/draw_v', 'text/draw_f')
		bu.dicts.Add(d)
		bu.link()


[System.STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		view = kri.ViewScreen()
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		pcon = kri.part.Context()
		pe = createParticle(pcon)
		pe.allocate()
		view.scene.particles.Add(pe)
		
		rlis.Add( kri.rend.Clear() )
		rlis.Add( Render(pcon) )
		win.core.anim = kri.ani.Particle(pe)
		win.Run(30.0,30.0)
		
		