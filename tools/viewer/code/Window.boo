namespace viewer

#import OpenTK.Graphics
#import OpenTK.Platform

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()


public class GladeApp:
	public def constructor():
		Gtk.Application.Init()
		scheme = Glade.XML('scheme/main.glade', 'KriViewer', null)
		scheme.Autoconnect( Gtk.Application )
		Gtk.Application.Run()
