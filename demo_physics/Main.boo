namespace demo

import System
import OpenTK
import OpenTK.Input


private class AniKey( kri.ani.IBase ):
	private final body	as kri.Body
	public def constructor(b as kri.Body):
		body = b
	def kri.ani.IBase.onFrame(time as double) as uint:
		kb = kri.Ant.Inst.Keyboard
		z = 0f
		if kb.Item[Key.Up]:		z = 1f
		if kb.Item[Key.Down]:	z = -1f
		body.vLinear = Vector3(0f,z,0f)
		return 0


[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant('kri.conf',0):
		view = kri.ViewScreen(8,0)
		rchain = kri.rend.Chain()
		view.ren = rchain
		rlis = rchain.renders
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		con = kri.load.Context()
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.scene.cameras.Add( view.cam )
		ant.anim = al = kri.ani.Scheduler()
		
		if not 'TestLandscape':
			hm = matrix(single,2,2)	# matrix[of single](2,2)
			hm[0,0] = 1f
			hm[0,1] = 1f
			hm[1,0] = 1f
			hm[1,1] = 1f
			mesh = kri.kit.gen.landscape(hm, Vector3.One)
			e = kri.Entity( mesh:mesh )
			e.tags.Add( kri.TagMat( mat:con.mDef, num:mesh.nPoly ) )
			view.scene.entities.Add(e)
		
		size = Vector3(1f,1f,1f)
		
		mesh = kri.kit.gen.cube( size )
		ent = kri.kit.gen.entity( mesh, con )
		ent.node = kri.Node('cube')
		ent.node.local.pos.Z = -10f
		ent.node.local.pos.Y = 1f
		ent.node.local.rot = Quaternion.FromAxisAngle(Vector3.UnitX,1f)
		view.scene.entities.Add(ent)
		
		mesh = kri.kit.gen.sphere( 1, size )
		e2 = kri.kit.gen.entity( mesh, con )
		e2.node = kri.Node('sphere')
		e2.node.local = ent.node.local
		e2.node.local.pos.Y = -1f
		view.scene.entities.Add(e2)
		
		rz = kri.rend.EarlyZ()
		rem = kri.rend.Emission( fillDepth:false )
		rem.backColor = Graphics.Color4(0.0f,0.1f,0.2f,1)
		#rem.pBase.Value = Graphics.Color4(1,0,0,1)
		rlis.Add( rz )
		rlis.Add( rem )
		
		b = kri.Body( ent.node, kri.ShapeSphere() )	# put some node here!
		#b.vAngular = Vector3(1f,0f,0f)
		#b.vLinear = Vector3(0f,0f,-0.2f)
		view.scene.bodies.Add(b)
		ren = kri.ani.sim.Render( view.scene, 5, rz )
		al.add( AniKey(b) )
		al.add(ren)
		texDebug = kri.shade.par.UnitProxy({ return ren.pr.Color })
		rlis.Add( kri.rend.debug.Map(false,-1,texDebug) )
		#texDepth = kri.shade.par.UnitProxy({ return ren.pr.Stencil })
		#rlis.Add( kri.rend.debug.Map(true,-1,texDepth) )
		
		ant.Run(30.0,30.0)
