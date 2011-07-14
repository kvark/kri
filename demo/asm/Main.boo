namespace demo.asm

import System
import OpenTK


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		win.core.extensions.AddRange((of kri.IExtension:
			support.skin.Extra(), support.layer.Extra() ))
		view = kri.ViewScreen()
		win.views.Add( view )
		win.VSync = VSyncMode.Off
		
		kri.lib.Journal.Inst = log = kri.lib.Journal()
		ln = kri.load.Native()
		at = ln.read('res/asm.scene')
		view.scene = at.scene
		view.cam = at.scene.cameras[0]
		view.ren = support.asm.Draw()
		
		support.asm.Scene( at.scene )

		#win.Run(0.0)
		log = null
