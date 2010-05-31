namespace test

import OpenTK

[System.STAThread]
public def Main(argv as (string)) as void:
	using ant = kri.Ant('kri.conf',24):
		view = kri.ViewScreen(16,0)
		view.ren = kri.rend.Chain()
		# populate render chain
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		# load scene
		ant.Run(30.0,30.0)
