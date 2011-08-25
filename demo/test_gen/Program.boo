namespace test_gen

import OpenTK

[System.STAThread]
def Main():
	using win=kri.Window('kri.conf',0):
		ct = kri.load.Context()
		view = kri.ViewScreen()
		win.views.Add(view)
		view.ren = rc = kri.rend.Chain()
		view.scene = scene = kri.Scene('main')
		view.cam = cam = kri.Camera()
		scene.cameras.Add( cam )
		cam.node = kri.Node('cam')
		cam.node.local.pos = Vector3(0f,0f,50f)
		# fill renderers
		rc.renders.Add( kri.rend.EarlyZ() )
		#rc.renders.Add( rem = kri.rend.Emission(fillDepth:true) )
		#rem.pBase.Value = Graphics.Color4.Red
		rc.renders.Add( kri.rend.debug.Attrib() )
		# generate content
		cone = kri.gen.Cone(10, 10f*Vector3.One)
		#cone = kri.gen.Sphere(3, 10f * Vector3.One)
		scene.entities.Add( ent = cone.wrap(ct.mDef) )
		ent.node = kri.Node('cone')
		win.core.anim = kri.ani.ControlMouse( win.Mouse, ent.node, view.cam, 0.01f )
		win.Run()
