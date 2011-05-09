namespace viewer

[System.STAThread]
public def Main(argv as (string)) as void:
	Gtk.Application.Init()
	ga = GladeApp()

	# startup options
	initScene	as string = null
	initPipe	as string = null
	doUpdate	= false
	doPlay		= false

	# post-init function
	ga.gw.Initialized += do(o as object, args as System.EventArgs):
		if initPipe:	ga.setPipe(initPipe)
		if initScene:	ga.load(initScene)
		if doUpdate:	ga.setDraw()
		if doPlay:		ga.playAll()

	# parse command line
	oScene	= '-scene='
	oPipe	= '-pipe='
	for ar in argv:
		if ar.StartsWith(oPipe):
			initPipe	= ar.Substring( oPipe.Length )
		elif ar.StartsWith(oScene):
			initScene	= ar.Substring( oScene.Length )
		elif ar == '-draw':	doUpdate = true
		elif ar == '-play':	doPlay = true

	# main loop
	Gtk.Application.Run()