namespace viewer

import OpenTK.Graphics

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
	[Glade.Widget]	propertyBook	as Gtk.Notebook
	[Glade.Widget]	objView			as Gtk.TreeView
	[Glade.Widget]	camFovLabel		as Gtk.Label
	[Glade.Widget]	camAspectLabel	as Gtk.Label
	[Glade.Widget]	camActiveBut	as Gtk.ToggleButton
	[Glade.Widget]	metaUnitLabel	as Gtk.Label
	[Glade.Widget]	metaShaderLabel	as Gtk.Label
	
	private	final	config	= kri.Config('kri.conf')
	private final	fps		= kri.FpsCounter(1.0,'Viewer')
	private	final	view	= kri.ViewScreen()
	private	final	dOpen	as Gtk.FileChooserDialog
	private rset	as RenderSet	= null
	private final	gw		as Gtk.GLWidget
	private	final	log		= kri.lib.Journal()
	private final	dialog	as Gtk.MessageDialog
	private	final	objTree		= Gtk.TreeStore(object)
	private final	magicOffset	= 17
	private	final	al		= kri.ani.Scheduler()
	private	curObj	as object	= null
	
	private def flushJournal() as bool:
		all = log.flush()
		if not all: return false
		gw.Visible = false
		dialog.Text = all
		dialog.Run()
		dialog.Hide()
		gw.Visible = true
		window.QueueDraw()
		return true
	
	private def addAnims(pl as kri.ani.data.Player) as void:
		if not pl:	return
		#for rec in pl.anims:
		#	aniList.AppendValues(rec)
	
	private def selectMat(m as kri.Material) as void:
		return
		/*if not m:
			entBook.Page = 1
			return
		entBook.Page = 0
		matLabel.Text = 'Material: '+ m.name
		for ch in metaBox.AllChildren:
			metaBox.Remove(ch)
		for meta in m.metaList:
			lab = Gtk.Label(meta.Name)
			lab.Visible = true
			metaBox.Add(lab)*/
	
	private def addPlayer(par as Gtk.TreeIter, ob as object) as void:
		pl = ob as kri.ani.data.Player
		if not pl: return
		for ani in pl.anims:
			objTree.AppendValues(par,ani)
	
	private def addObject(par as Gtk.TreeIter, ob as object) as Gtk.TreeIter:
		if not ob:	return par
		it = objTree.AppendValues(par,ob)
		addPlayer(it,ob)
		return it
	
	private def addObject(ob as object) as Gtk.TreeIter:
		it = objTree.AppendValues(ob)
		on = ob as kri.INoded
		if on:	addObject(it,on.Node)
		addPlayer(it,ob)
		return it
		
	private def updateList() as void:
		objTree.Clear()
		if not view.scene:
			return
		for cam in view.scene.cameras:
			addObject(cam)
		for lit in view.scene.lights:
			addObject(lit)
		for ent in view.scene.entities:
			it = addObject(ent)
			for tag in ent.tags:
				td = tag as kri.ITagData
				if td:	addObject(it,td.Data)
		for par in view.scene.particles:
			it = addObject(par)
			addObject( it, par.owner )
	
	# signals
	
	public def onInit(o as object, args as System.EventArgs) as void:
		ant = kri.Ant(config,true)
		ant.extensions.AddRange((of kri.IExtension:
			support.skin.Extra(), support.corp.Extra(), support.morph.Extra()
			))
		ant.anim = al
		rset = RenderSet()
		view.ren = rset.gen( Scheme.Forward )
		r = gw.Allocation
		view.resize( 0, magicOffset, r.Width, r.Height )
		selectMat(null)
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		core = kri.Ant.Inst
		if not core:	return
		try:
			core.update(1)
			view.update()
		except e:
			dialog.Text = e.StackTrace
		if fps.update(core.Time):
			window.Title = fps.gen()
		#window.QueueDraw()
		flushJournal()
	
	public def onSize(o as object, args as Gtk.SizeAllocatedArgs) as void:
		if not view.ren:
			return
		r = args.Allocation
		view.resize( 0, magicOffset, r.Width, r.Height )
		window.QueueDraw()	# temporary bug fix
		statusBar.Push(0, 'Resized into '+r.Width+'x'+r.Height )
	
	public def onButClear(o as object, args as System.EventArgs) as void:
		view.scene = null
		view.cam = null
		objTree.Clear()
		window.QueueDraw()
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
		updateList()
		flushJournal()
		gw.QueueDraw()
		statusBar.Push(0, 'Loaded ' + path.Substring(pos+1) )
	
	public def onSelectObj(o as object, args as System.EventArgs) as void:
		iter = Gtk.TreeIter()
		if not objView.Selection.GetSelected(iter):
			return
		curObj = obj = objTree.GetValue(iter,0)
		propertyBook.Page = 0
		meta = obj as kri.meta.Advanced
		cam = obj as kri.Camera
		if obj isa kri.Entity:
			propertyBook.Page = 1
		if obj isa kri.Node:
			propertyBook.Page = 2
		if obj isa kri.Material:
			propertyBook.Page = 3
		if cam:
			propertyBook.Page = 4
			camFovLabel.Text = 'Fov: ' + cam.fov
			camAspectLabel.Text = 'Aspect: ' + cam.aspect
			camActiveBut.Active = view.cam == cam
		if obj isa kri.Light:
			propertyBook.Page = 5
		if obj isa kri.ani.data.Record:
			propertyBook.Page = 6
		if meta:
			metaUnitLabel.Text = 'Unit: ' + meta.Unit
			if meta.Shader:
				metaShaderLabel.Text = meta.Shader.Description
			propertyBook.Page = 7
	
	public def onActivateObj(o as object, args as Gtk.RowActivatedArgs) as void:
		it = Gtk.TreeIter()
		assert objTree.GetIter(it, args.Path )
		if not objTree.IterHasChild(it):
			ox = objTree.GetValue(it,0)
			mat = ox as kri.Material
			if mat:
				for unit in mat.unit:
					objTree.AppendValues(it,unit)
				for meta in mat.metaList:
					objTree.AppendValues(it,meta)
		objView.ExpandRow( args.Path, true )
	
	public def onSelectAni(o as object, args as System.EventArgs) as void:
		return
	
	public def onPlayAni(o as object, args as Gtk.RowActivatedArgs) as void:
		return
		/*iter = Gtk.TreeIter()
		aniTree.Selection.GetSelected(iter)
		rec = aniList.GetValue(iter,0)	as kri.ani.data.Record
		objTree.Selection.GetSelected(iter)
		obj = objList.GetValue(iter,0)	as kri.ani.data.Player
		assert rec and obj
		al.add( kri.ani.data.Anim(obj,rec) )*/
	
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
		obj = model.GetValue(iter,0)
		text = obj.GetType().ToString()
		icon = 'file'
		iNoded = obj as kri.INoded
		if iNoded and iNoded.Node:
			text = iNoded.Node.name
		if obj isa kri.Camera:
			icon = 'fullscreen'
		if obj isa kri.Light:
			icon = 'dialog-info'
		if obj isa kri.Entity:
			icon = 'orientation-portrait'
		if obj isa kri.part.Emitter:
			icon = 'about'
		if obj isa kri.Node:
			text = 'node'
			icon = 'sort-descending'
		if obj isa kri.Skeleton:
			text = 'sleleton'
			icon = 'disconnect'
		mat = obj as kri.Material
		if mat:
			text = mat.name
			icon = 'select-color'
		rec = obj as kri.ani.data.Record
		if rec:
			text = "${rec.name} (${rec.length})"
			icon = 'cdrom'
		mad = obj as kri.meta.Advanced
		if mad:
			text = mad.Name
			icon = 'color-picker'
		mun = obj as kri.meta.AdUnit
		if mun:
			text = '(empty)'
			icon = 'harddisk'
			tt = mun.Value
			if tt:	text = tt.target.ToString()
		# set the result
		ct = cell as Gtk.CellRendererText
		if ct:	ct.Text = text
		cp = cell as Gtk.CellRendererPixbuf
		if cp:	cp.StockId = 'gtk-'+icon

	
	private def tagFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		tag = model.GetValue(iter,0) as kri.ITag
		cr = cell as Gtk.CellRendererText
		assert tag and cr
		cr.Text = tag.GetType().ToString()
	
	private def aniFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		rec = model.GetValue(iter,0) as kri.ani.data.Record
		cr = cell as Gtk.CellRendererText
		assert rec and cr
		cr.Text = "${rec.name} (${rec.length})"
	
	private def makeColumn() as Gtk.TreeViewColumn:
		col = Gtk.TreeViewColumn()
		col.Title = 'Objects:'
		rPix = Gtk.CellRendererPixbuf()
		col.PackStart(rPix,false)
		col.SetCellDataFunc( rPix, objFunc )
		rTex = Gtk.CellRendererText()
		col.PackEnd(rTex,true)
		col.SetCellDataFunc( rTex, objFunc )
		return col
	
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
		propertyBook.ShowTabs = false
		objView.AppendColumn( makeColumn() )
		#objView.AppendColumn( 'Object:', Gtk.CellRendererText(), objFunc )
		objView.Model = objTree
		objView.CursorChanged	+= onSelectObj
		objView.RowActivated	+= onActivateObj
		camActiveBut.Clicked	+= do(o as object, args as System.EventArgs):
			curCam = curObj as kri.Camera
			if view.cam != curCam:
				camActiveBut.Active = true
				view.cam = curCam
		# add gl widget
		drawBox.Child = gw = makeWidget()
		gw.Initialized		+= onInit
		gw.RenderFrame		+= onFrame
		gw.SizeAllocated	+= onSize
		gw.Visible = true
		# run
		statusBar.Push(0, 'Started')
		manual = false
		if manual:
			while window.Visible:
				if not Gtk.Application.EventsPending():
					onFrame(null,null)
				Gtk.Application.RunIteration()
		else:
			Gtk.Application.Run()
