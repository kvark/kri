namespace linker

[System.STAThread]
public def Main(argv as (string)) as void:
	Gtk.Application.Init()
	#ga = GladeApp()
	Gtk.Application.Run()
	#ga = null
