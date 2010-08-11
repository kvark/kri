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


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		view = kri.ViewScreen()
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		view.scene = kri.Scene('main')
		view.cam = kri.Camera()
		view.cam.makeOrtho(1f)
		view.scene.lights.Add( kri.Light() )
		
		view.ren = rc = kri.rend.Chain()
		rc.renders.Add( wat = Water() )
		wat.setKernel(6,8)
		wat.lit = kri.Light()
		wat.lit.node = n = kri.Node('lit')
		n.local.pos = Vector3(5f,3f,10f)
		
		win.Run(30.0,30.0)
