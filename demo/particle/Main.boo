namespace demo

import System
import OpenTK


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
		land.tags.Add( pTag = support.bake.depth.Tag() )
		pTag.Size = 256
		pro = pTag.proj
		pro.node = kri.Node('proj')
		pro.node.local.pos.Z = 5f
		pro.makeOrtho( 2f * land.node.local.scale )
		pro.setRanges( 1f, 6f )
		
		man = at.scene.particles[0].owner
		man.behos.Add( support.bake.depth.Behavior(pTag) )
		man.col_update.extra.Add( kri.shade.Object.Load('/lib/tool_v') )
		man.init( cex.pcon )
		
		rlis.Add( support.bake.surf.Update() )
		rlis.Add( support.bake.depth.Update() )
		rlis.Add( rem = kri.rend.Emission(fillDepth:true) )
		rem.pBase.Value = Graphics.Color4.Black
		
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
