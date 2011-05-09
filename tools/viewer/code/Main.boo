namespace viewer

[System.STAThread]
public def Main(argv as (string)) as void:
	Gtk.Application.Init()
	ga = GladeApp()
	for ar in argv:
		if not ar.StartsWith('-'):
			ga.load(ar)
		elif ar == '-draw':
			ga.setDraw()
		elif ar == '-play':
			ga.playAll()
		elif ar.StartsWith('-pipe='):
			ga.setPipe( ar.Substring(5) )
	# main loop
	Gtk.Application.Run()