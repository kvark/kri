namespace viewer

import OpenTK.Graphics
import System.Collections.Generic

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()


public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	drawBox			as Gtk.Container
	[Glade.Widget]	statusBar		as Gtk.Statusbar
	[Glade.Widget]	toolBar			as Gtk.Toolbar
	[Glade.Widget]	butClear		as Gtk.ToolButton
	[Glade.Widget]	butOpen			as Gtk.ToolButton
	[Glade.Widget]	noteBook		as Gtk.Notebook
	[Glade.Widget]	objTree			as Gtk.TreeView
	[Glade.Widget]	aniTree			as Gtk.TreeView
	[Glade.Widget]	tagTree			as Gtk.TreeView
	
	private	final	config	= kri.Config('kri.conf')
	private	final	view	= kri.ViewScreen()
	private	final	dOpen	as Gtk.FileChooserDialog
	private rset	as RenderSet	= null
	private final	gw		as Gtk.GLWidget
	private	final	log		= kri.lib.Journal()
	private final	dialog	as Gtk.MessageDialog
	private	final	objList		= Gtk.ListStore(kri.INoded)
	private	final	tagList		= Gtk.ListStore(kri.ITag)
	private	final	aniList		= Gtk.ListStore(string,single)
	
	private def flushJournal() as bool:
		all = log.flush()
		if not all: return false
		gw.Visible = false
		dialog.Text = all
		dialog.Run()
		dialog.Hide()
		gw.Visible = true
		#window.QueueDraw()
		return true
	
	private def fillObjNames[of T(kri.INoded)](list as List[of T]) as void:
		objList.Clear()
		for an in list:
			n = an.Node
			if not n: continue
			objList.AppendValues(an)
	
	private def selectPage(id as byte) as void:
		if not (view and view.scene):
			return
		if id == 0:
			fillObjNames( view.scene.entities )
		if id == 1:
			fillObjNames( view.scene.lights )
		if id == 2:
			fillObjNames( view.scene.cameras )
	
	
	# signals
	
	public def onInit(o as object, args as System.EventArgs) as void:
		ant = kri.Ant(config,true)
		ant.extensions.Add( support.skin.Extra() )
		rset = RenderSet()
		view.ren = rset.gen( Scheme.Forward )
		r = gw.Allocation
		view.resize( r.Width, r.Height )
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		kri.Ant.Inst.update(1)
		try:
			view.update()
		except e:
			dialog.Text = e.StackTrace
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
		selectPage(0)
		gw.QueueDraw()
		statusBar.Push(0, 'Cleared')
	
	public def onButOpen(o as object, args as System.EventArgs) as void:
		if not kri.Ant.Inst:
			return
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
		try:
			at = loader.read(path)
		except e:
			dialog.Text = e.StackTrace
		view.scene = at.scene
		if at.scene.cameras.Count:
			view.cam = at.scene.cameras[0]
		# notify
		selectPage(0)
		flushJournal()
		gw.QueueDraw()
		statusBar.Push(0, 'Loaded ' + path.Substring(pos+1) )
	
	public def onSwitchPage(o as object, args as Gtk.SwitchPageArgs) as void:
		tagList.Clear()
		selectPage( args.PageNum )
	
	public def onSelectObj(o as object, args as System.EventArgs) as void:
		iter = Gtk.TreeIter()
		if not objTree.Selection.GetSelected(iter):
			return
		obj = objList.GetValue(iter,0)
		# fill animations
		aniList.Clear()
		pl = obj as kri.ani.data.Player
		if pl:
			for rec in pl.anims:
				aniList.AppendValues( rec.name, rec.length )
		# fill object-specific info	
		ent = obj as kri.Entity
		if ent:
			tagList.Clear()
			for tg in ent.tags:
				tagList.AppendValues(tg)
	
	public def onSelectAni(o as object, args as System.EventArgs) as void:
		x = 0
	
	# construction
			
	private def makeWidget() as Gtk.GLWidget:
		context	= config.ask('Context','0')
		bug = context.EndsWith('d')
		ver = uint.Parse( context.TrimEnd(*'rd'.ToCharArray()) )
		gm = GraphicsMode( ColorFormat(8), 24, 8 )
		conFlags  = GraphicsContextFlags.ForwardCompatible
		if bug:	conFlags |= GraphicsContextFlags.Debug	
		return Gtk.GLWidget(gm,3,ver,conFlags)
	
	private def objFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		obj = model.GetValue(iter,0) as kri.INoded
		cr = cell as Gtk.CellRendererText
		assert obj and cr
		node = obj.Node
		if node:	cr.Text = node.name
		else:		cr.Text = null
	
	private def tagFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		tag = model.GetValue(iter,0) as kri.ITag
		cr = cell as Gtk.CellRendererText
		assert tag and cr
		cr.Text = tag.GetType().ToString()
	
	private def aniFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		str = model.GetValue(iter,0) as string
		length = cast(single,model.GetValue(iter,0))
		cr = cell as Gtk.CellRendererText
		assert str and cr
		cr.Text = "${str} (${length})"
	
	public def constructor():
		Gtk.Application.Init()
		kri.lib.Journal.Inst = log
		# load scheme
		scheme = Glade.XML('scheme/main.glade', 'window', null)
		scheme.Autoconnect(self)
		window.DeleteEvent	+= onDelete
		dialog = Gtk.MessageDialog( window, Gtk.DialogFlags.Modal,
			Gtk.MessageType.Warning, Gtk.ButtonsType.Ok, null )
		# make toolbar
		butClear.Clicked	+= onButClear
		butOpen.Clicked 	+= onButOpen
		dOpen = Gtk.FileChooserDialog('Select KRI scene to load:',
			window, Gtk.FileChooserAction.Open )
		dOpen.AddButton('Load',0)
		filter = Gtk.FileFilter( Name:'kri scenes' )
		filter.AddPattern("*.scene")
		dOpen.AddFilter(filter)
		# make panel
		objTree.AppendColumn('Objects:', Gtk.CellRendererText(), objFunc)
		objTree.Model = objList
		objTree.CursorChanged += onSelectObj
		aniTree.AppendColumn('Animations:', Gtk.CellRendererText(), aniFunc)
		aniTree.Model = aniList
		aniTree.CursorChanged += onSelectAni
		tagTree.AppendColumn('Tags:', Gtk.CellRendererText(), tagFunc)
		tagTree.Model = tagList
		noteBook.SwitchPage += onSwitchPage
		# add gl widget
		drawBox.Child = gw = makeWidget()
		gw.Initialized		+= onInit
		gw.RenderFrame		+= onFrame
		gw.SizeAllocated	+= onSize
		gw.Visible = true
		# run
		statusBar.Push(0, 'Started')
		Gtk.Application.Run()
