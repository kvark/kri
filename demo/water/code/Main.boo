namespace demo.water

import System
import OpenTK


public class Calculator:
	public final samples	as uint
	public final dq			as single
	public final sigma		as single
	public def constructor(n as uint, q as single, s as single):
		samples = n
		dq,sigma = q,s
	public def gen(multi as callable(single) as single) as single:
		rez = 0f
		for i in range(samples):
			qn = i * dq
			q2 = qn * qn
			rez += q2 * Math.Exp(-sigma * q2) * multi(qn)
		return rez

private def genTown(size as uint, amp as single) as kri.Entity:
	con = kri.load.Context()
	grid = matrix(single,size,size)
	rand = Random()
	for i in range(size):
		for j in range(size):
			val = rand.NextDouble()
			grid[i,j] = cast(single,val)
	ds = 1f / size
	mesh = kri.gen.Landscape(grid, Vector3(ds,ds,ds*amp))
	return kri.gen.Entity(mesh,con)


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		view = kri.ViewScreen()
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.cam.makeOrtho(1f)
		lit = kri.Light()
		lit.energy = 0.5f
		lit.fov = 0f
		view.scene.lights.Add(lit)
		
		mod = ''
		node = kri.Node('town')
		node.local.pos.Z = -10f
		
		if mod == 'Town':
			town = genTown(10,3f)
			town.node = node
			view.scene.entities.Add(town)
		elif mod == 'Primitives':
			lcon = kri.load.Context()
			t0 = kri.gen.Entity( kri.gen.Plane(Vector2.One), lcon )
			t1 = kri.gen.Entity( kri.gen.Cube(0.2*Vector3.One), lcon )
			t0.node = kri.Node('plane')
			t0.node.local.pos.Z = -10f
			t1.node = node
			node.local.rot = Quaternion.FromAxisAngle(Vector3(0.3,0.5,0.1),0.6)
			view.scene.entities.AddRange((t0,t1))
		
		con = Context()
		con.setKernel(7)
		win.core.anim = ac = kri.ani.Scheduler()
		#ac.add( kri.ani.ControlMouse( win.Mouse, node, 0.01f ))
		utouch = Update(con,win)
		ac.add( utouch )
		ac.add( Touch(win,con) )
		
		view.ren = rc = kri.rend.Chain()
		rlis = rc.renders
		rlis.Add( rt = Town() )
		rlis.Add( kri.rend.Emission( fillDepth:true ) )
		rlis.Add( kri.rend.light.omni.Apply(false) )
		rlis.Add( wat = Draw(con) )
		wat.pTownTex.Value = rt.Result
		wat.pTownPos.Value = Vector4(1f,1f,0f,0f)
		#rlis.Remove(wat)
		wat.lit = lit
		wat.lit.node = n = kri.Node('lit')
		n.local.pos = Vector3(1f,2f,10f)
		
		win.Run(30.0,30.0)
