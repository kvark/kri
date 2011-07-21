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
		view.ren = support.asm.DrawSimple()
		view.scene = support.asm.Scene( 200, at.scene )

		win.Run(0.0)
		log = null
