namespace viewer

import OpenTK.Graphics

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()


public class GladeApp:
	[Glade.Widget]	window		as Gtk.Window
	[Glade.Widget]	viewport	as Gtk.Viewport
	private	final config	= kri.Config('kri.conf')
	
	public def onInit(o as object, args as System.EventArgs) as void:
		kri.Ant(config,true)
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		kri.Ant.Inst.update(1)
	
	private def makeWidget() as Gtk.GLWidget:
		context	= config.ask('Context','0')
		bug = context.EndsWith('d')
		ver = uint.Parse( context.TrimEnd(*'rd'.ToCharArray()) )
		gm = GraphicsMode( ColorFormat(8), 24, 8 )
		conFlags  = GraphicsContextFlags.ForwardCompatible
		if bug:	conFlags |= GraphicsContextFlags.Debug	
		return Gtk.GLWidget(gm,3,ver,conFlags)
	
	public def constructor():
		Gtk.Application.Init()
		Gtk.GLWidget.GraphicsContextInitialized		+= onInit
		# load scheme
		scheme = Glade.XML('scheme/main.glade', 'window', null)
		scheme.Autoconnect(self)
		window.DeleteEvent += onDelete
		# add gl widget
		gw = makeWidget()
		gw.RenderFrame += onFrame
		viewport.Add(gw)
		gw.Visible = true
		# run
		Gtk.Application.Run()
