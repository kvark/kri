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
		
		rz = kri.rend.EarlyZ()
		rem = kri.rend.Emission( fillDepth:false )
		rem.backColor = Graphics.Color4(0.0f,0.1f,0.2f,1)
		#rem.pBase.Value = Graphics.Color4(1,0,0,1)
		rlis.Add( rz )
		rlis.Add( rem )
		
		if 'TestLandscape':
			hm = matrix(single,3,3)	# matrix[of single](2,2)
			for i in range(3):
				for j in range(3):
					hm[i,j] = 2f - Math.Abs(i-1) - Math.Abs(j-1)
			mesh = kri.kit.gen.landscape(hm, Vector3.One)
			e = kri.Entity( mesh:mesh )
			e.tags.Add( kri.TagMat( mat:con.mDef, num:mesh.nPoly ) )
			n = e.node = kri.Node('landscape')
			n.local.pos.Z = -10f
			n.local.pos.Y = 0f
			n.local.rot = Quaternion.FromAxisAngle(Vector3.UnitX,0f)
			view.scene.entities.Add(e)
			
			al.add( kri.ani.ControlMouse(n,0.1f) )
			lic = kri.rend.light.Context(2,2)
			rlis.Add( kri.rend.light.Fill(lic) )
			rlis.Add( kri.rend.light.Apply(lic) )
			view.scene.lights.Add( kri.Light() )
		
		size = Vector3(1f,1f,1f)
		
		mesh = kri.kit.gen.cube( size )
		ent = kri.kit.gen.entity( mesh, con )
		n = ent.node = kri.Node('cube')
		n.local.pos.Z = -10f
		n.local.pos.Y = 1f
		n.local.rot = Quaternion.FromAxisAngle(Vector3.UnitX,1f)
		#view.scene.entities.Add(ent)
		
		mesh = kri.kit.gen.sphere( 1, size )
		e2 = kri.kit.gen.entity( mesh, con )
		n = e2.node = kri.Node('sphere')
		n.local = ent.node.local
		n.local.pos.Y = -1f
		#view.scene.entities.Add(e2)
		
		b = kri.Body( ent.node, kri.ShapeSphere() )	# put some node here!
		#b.vAngular = Vector3(1f,0f,0f)
		#b.vLinear = Vector3(0f,0f,-0.2f)
		view.scene.bodies.Add(b)
		ren = kri.ani.sim.Render( view.scene, 4, rz )
		al.add( AniKey(b) )
		al.add(ren)
		if not 'Debug':
			texDebug = kri.shade.par.UnitProxy({ return ren.pr.Color })
			rlis.Add( kri.rend.debug.Map(false,-1,texDebug) )
			#texDepth = kri.shade.par.UnitProxy({ return ren.pr.Stencil })
			#rlis.Add( kri.rend.debug.Map(true,-1,texDepth) )
		
		ant.Run(30.0,30.0)
