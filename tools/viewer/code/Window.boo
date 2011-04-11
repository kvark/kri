namespace viewer

import OpenTK.Graphics

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()


public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	hBox			as Gtk.HBox
	[Glade.Widget]	statusBar		as Gtk.Statusbar
	[Glade.Widget]	toolBar			as Gtk.Toolbar
	[Glade.Widget]	butClear		as Gtk.ToolButton
	[Glade.Widget]	butOpen			as Gtk.ToolButton
	
	private	final	config	= kri.Config('kri.conf')
	private	final	view	= kri.ViewScreen()
	private	final	dOpen	as Gtk.FileChooserDialog
	private rset	as RenderSet	= null
	private final	gw		as Gtk.GLWidget
	private	final	log		= kri.lib.Journal()
	private final	dialog	as Gtk.MessageDialog
	
	private def flushJournal() as bool:
		all = log.flush()
		if not all: return false
		gw.Visible = false
		dialog.Text = all
		dialog.Run()
		dialog.Hide()
		gw.Visible = true
		return true
	
	# signals
	
	public def onInit(o as object, args as System.EventArgs) as void:
		kri.Ant(config,true)
		rset = RenderSet()
		view.ren = rset.gen( Scheme.Simple )
		r = gw.Allocation
		view.resize( r.Width, r.Height )
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		kri.Ant.Inst.update(1)
		view.update()
		flushJournal()
	
	public def onSize(o as object, args as Gtk.SizeAllocatedArgs) as void:
		if not view.ren:
			return
		r = args.Allocation
		view.resize( r.Width, r.Height )
		statusBar.Push(0, 'Resized into '+r.Width+'x'+r.Height )
	
	public def onButClear(o as object, args as System.EventArgs) as void:
		view.scene = null
		view.cam = null
		gw.QueueDraw()
		statusBar.Push(0, 'Cleared')
	
	public def onButOpen(o as object, args as System.EventArgs) as void:
		rez = dOpen.Run()
		dOpen.Hide()
		if rez != 0:
			statusBar.Push(0, 'Load cancelled')
			return
		path = dOpen.Filename
		pos = path.LastIndexOfAny((char('/'),char('\\')))
		fdir = path.Substring(0,pos)
		# load scene
		kri.Ant.Inst.loaders.materials.prefix = fdir
		loader = kri.load.Native()
		at = loader.read(path)
		view.scene = at.scene
		if at.scene.cameras.Count:
			view.cam = at.scene.cameras[0]
		# notify
		flushJournal()
		gw.QueueDraw()
		statusBar.Push(0, 'Loaded ' + path.Substring(pos+1) )
	
	# construction
			
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
		dialog = Gtk.MessageDialog( window, Gtk.DialogFlags.Modal,
			Gtk.MessageType.Error, Gtk.ButtonsType.Ok, null )
		kri.lib.Journal.Inst = log
		# load scheme
		scheme = Glade.XML('scheme/main.glade', 'window', null)
		scheme.Autoconnect(self)
		window.DeleteEvent	+= onDelete
		# make toolbar
		butClear.Clicked	+= onButClear
		butOpen.Clicked 	+= onButOpen
		dOpen = Gtk.FileChooserDialog('Select KRI scene to load:',
			window, Gtk.FileChooserAction.Open )
		dOpen.AddButton('Load',0)
		filter = Gtk.FileFilter( Name:'kri scenes' )
		filter.AddPattern("*.scene")
		dOpen.AddFilter(filter)
		# add gl widget
		gw = makeWidget()
		gw.Initialized		+= onInit
		gw.RenderFrame		+= onFrame
		gw.SizeAllocated	+= onSize
		hBox.PackStart(gw)
		gw.Visible = true
		# run
		statusBar.Push(0, 'Started')
		Gtk.Application.Run()
