namespace demo.asm

import System
import OpenTK


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		win.core.extensions.AddRange((of kri.IExtension:
			support.skin.Extra(), support.layer.Extra() ))
		view = support.asm.View()
		win.views.Add( view )
		win.VSync = VSyncMode.Off
		
		kri.lib.Journal.Inst = log = kri.lib.Journal()
		ln = kri.load.Native()
		at = ln.read('res/asm.scene')
		view.cam = at.scene.cameras[0]
		con = support.asm.Context()
		view.ren = support.asm.DrawSimple(con)
		view.scene = support.asm.Scene( 200, at.scene )
		view.scene.lights.AddRange( at.scene.lights )
		
		v2 = kri.ViewScreen()
		#win.views.Add(v2)
		v2.cam = view.cam
		v2.scene = at.scene
		v2.ren = kri.rend.debug.Attrib()

		win.Run(0.0)
		if log.messages.Count:
			log.flush()
