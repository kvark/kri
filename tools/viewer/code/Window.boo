namespace viewer

import OpenTK.Graphics

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()


public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	hbox1			as Gtk.HBox
	[Glade.Widget]	menuFileOpen	as Gtk.ImageMenuItem
	
	private	final	config	= kri.Config('kri.conf')
	private	final	view	= kri.ViewScreen()
	private	final	dOpen	as Gtk.FileChooserDialog
	private rset	as RenderSet	= null
	private final	gw		as Gtk.GLWidget
	
	public def onInit(o as object, args as System.EventArgs) as void:
		kri.Ant(config,true)
		rset = RenderSet()
		view.ren = rset.gen( Scheme.Simple )
		view.resize( gw.Allocation.Width, gw.Allocation.Height )
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		kri.Ant.Inst.update(1)
		view.update()
	
	public def onSize(o as object, args as Gtk.SizeAllocatedArgs) as void:
		if view.ren:
			view.resize( args.Allocation.Width, args.Allocation.Height )
	
	public def onMenuOpen(o as object, args as System.EventArgs) as void:
		if dOpen.Run() != 0:
			return
		dOpen.Hide()
		path = dOpen.Filename
		fdir = path.Substring( 0, path.LastIndexOfAny((char('/'),char('\\'))) )
		kri.Ant.Inst.loaders.materials.prefix = fdir
		loader = kri.load.Native()
		at = loader.read(path)
		view.scene = at.scene
		if at.scene.cameras.Count:
			view.cam = at.scene.cameras[0]
			
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
		menuFileOpen.Activated += onMenuOpen
		dOpen = Gtk.FileChooserDialog('Select KRI scene to load',
			window, Gtk.FileChooserAction.Open, Gtk.ButtonsType.OkCancel )
		dOpen.AddButton('Open',0)
		filter = Gtk.FileFilter()
		filter.AddPattern("*.scene")
		dOpen.AddFilter(filter)
		# add gl widget
		gw = makeWidget()
		gw.RenderFrame += onFrame
		gw.SizeAllocated += onSize
		hbox1.PackStart(gw)
		gw.Visible = true
		# run
		Gtk.Application.Run()
