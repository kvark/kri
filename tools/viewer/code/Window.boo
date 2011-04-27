namespace viewer

import OpenTK.Graphics

[System.STAThread]
public def Main(argv as (string)) as void:
	GladeApp()

private class AtBox:
	public final info	as kri.vb.Info
	public def constructor(ai as kri.vb.Info):
		info = ai


public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	drawBox			as Gtk.Container
	[Glade.Widget]	statusBar		as Gtk.Statusbar
	[Glade.Widget]	toolBar			as Gtk.Toolbar
	[Glade.Widget]	butClear		as Gtk.ToolButton
	[Glade.Widget]	butOpen			as Gtk.ToolButton
	[Glade.Widget]	butDraw			as Gtk.ToggleToolButton
	[Glade.Widget]	propertyBook	as Gtk.Notebook
	[Glade.Widget]	objView			as Gtk.TreeView
	[Glade.Widget]	camFovLabel		as Gtk.Label
	[Glade.Widget]	camAspectLabel	as Gtk.Label
	[Glade.Widget]	camActiveBut	as Gtk.ToggleButton
	[Glade.Widget]	metaUnitLabel	as Gtk.Label
	[Glade.Widget]	metaShaderLabel	as Gtk.Label
	[Glade.Widget]	meshModeLabel	as Gtk.Label
	[Glade.Widget]	meshVertLabel	as Gtk.Label
	[Glade.Widget]	meshPolyLabel	as Gtk.Label
	[Glade.Widget]	attrTypeLabel	as Gtk.Label
	[Glade.Widget]	attrSizeLabel	as Gtk.Label
	[Glade.Widget]	entVisibleBut	as Gtk.ToggleButton
	[Glade.Widget]	aniPlayBut		as Gtk.Button
	
	private	final	config	= kri.Config('kri.conf')
	private final	fps		= kri.FpsCounter(1.0,'Viewer')
	private	final	view	= kri.ViewScreen()
	private	final	dOpen	as Gtk.FileChooserDialog
	private rset	as RenderSet	= null
	private final	gw		as Gtk.GLWidget
	private	final	log		= kri.lib.Journal()
	private final	dialog	as Gtk.MessageDialog
	private	final	objTree		= Gtk.TreeStore(object)
	private	final	al		= kri.ani.Scheduler()
	private	curObj	as object	= null
	private	curIter	= Gtk.TreeIter.Zero
	
	private def flushJournal() as bool:
		all = log.flush()
		if not all: return false
		gw.Visible = false
		dialog.Text = all
		dialog.Run()
		dialog.Hide()
		gw.Visible = true
		return true
	
	private def addPlayer(par as Gtk.TreeIter, ob as object) as void:
		pl = ob as kri.ani.data.Player
		if not pl: return
		for ani in pl.anims:
			objTree.AppendValues(par,ani)
	
	private def addObject(par as Gtk.TreeIter, ob as object) as Gtk.TreeIter:
		if not ob:	return par
		if par == Gtk.TreeIter.Zero:
			it = objTree.AppendValues(ob)
		else:
			it = objTree.AppendValues(par,ob)
		on = ob as kri.INoded
		if on:	addObject(it, on.Node)
		me = ob as kri.IMeshed
		if me:	addObject(it, me.Mesh)
		addPlayer(it,ob)
		return it
	
	private def addObject(ob as object) as Gtk.TreeIter:
		return addObject( Gtk.TreeIter.Zero, ob )
		
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
			addObject( it, ent.store )
			for tag in ent.tags:
				td = tag as kri.ITagData
				if td:	addObject(it,td.Data)
		for par in view.scene.particles:
			it = addObject(par)
			addObject( it, par.owner )


	#--------------------	
	# signals
	
	public def onException(args as GLib.UnhandledExceptionArgs) as void:
		args.ExitApplication = true
		System.IO.File.WriteAllText( 'exception.txt', args.ExceptionObject.ToString() )
	
	public def onInit(o as object, args as System.EventArgs) as void:
		ant = kri.Ant(config,true)
		ant.extensions.AddRange((of kri.IExtension:
			support.skin.Extra(), support.corp.Extra(), support.morph.Extra()
			))
		ant.anim = al
		rset = RenderSet()
		view.ren = rset.gen( Scheme.Forward )
		gw.QueueResize()
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onIdle() as bool:
		if butDraw.Active:
			gw.QueueDraw()
		return true
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		core = kri.Ant.Inst
		if not core:	return
		core.update(1)
		view.update()
		if butDraw.Active:
			if fps.update(core.Time):
				window.Title = fps.gen()
		else:	window.Title = 'Viewer'
		flushJournal()
	
	public def onSize(o as object, args as Gtk.SizeAllocatedArgs) as void:
		if not view.ren:
			return
		r = args.Allocation
		view.resize( 0, 0, r.Width, r.Height )
		statusBar.Push(0, 'Resized into '+r.Width+'x'+r.Height )
	
	public def onButClear(o as object, args as System.EventArgs) as void:
		view.scene = null
		view.cam = null
		objTree.Clear()
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
		at = loader.read(path)
		view.scene = at.scene
		if at.scene.cameras.Count:
			view.cam = at.scene.cameras[0]
		# notify
		updateList()
		flushJournal()
		gw.QueueDraw()
		statusBar.Push(0, 'Loaded ' + path.Substring(pos+1) )
	
	public def onSelectObj(o as object, args as System.EventArgs) as void:
		curIter = Gtk.TreeIter()
		if not objView.Selection.GetSelected(curIter):
			return
		curObj = obj = objTree.GetValue(curIter,0)
		propertyBook.Page = 0
		if (ent = obj as kri.Entity):
			entVisibleBut.Active = ent.visible
			propertyBook.Page = 1
		if obj isa kri.Node:
			propertyBook.Page = 2
		if obj isa kri.Material:
			propertyBook.Page = 3
		if (cam = obj as kri.Camera):
			propertyBook.Page = 4
			camFovLabel.Text = 'Fov: ' + cam.fov
			camAspectLabel.Text = 'Aspect: ' + cam.aspect
			camActiveBut.Active = view.cam == cam
		if obj isa kri.Light:
			propertyBook.Page = 5
		if obj isa kri.ani.data.Record:
			propertyBook.Page = 6
		if (meta = obj as kri.meta.Advanced):
			metaUnitLabel.Text = 'Unit: ' + meta.Unit
			if meta.Shader:
				metaShaderLabel.Text = meta.Shader.Description
			propertyBook.Page = 7
		if (mesh = obj as kri.Mesh):
			meshModeLabel.Text = mesh.drawMode.ToString()
			meshVertLabel.Text = 'nVert: ' + mesh.nVert
			meshPolyLabel.Text = 'nPoly: ' + mesh.nPoly
			propertyBook.Page = 8
		if (box = obj as AtBox):
			attrTypeLabel.Text = box.info.type.ToString()
			attrSizeLabel.Text = 'Size: ' + box.info.size + ('','i')[box.info.integer]
			propertyBook.Page = 9
	
	public def onActivateObj(o as object, args as Gtk.RowActivatedArgs) as void:
		par = it = Gtk.TreeIter()
		inMat = inAni = inStore = inOwner = true
		objTree.GetIter(par,args.Path)
		rez = objTree.IterChildren(it,par)
		while rez:
			ox = objTree.GetValue(it,0)
			if (ox isa kri.meta.AdUnit) or (ox isa kri.meta.Advanced):
				inMat = false
			if ox isa kri.ani.data.IChannel:
				inAni = false
			if ox isa AtBox:
				inStore = false
			if ox isa kri.part.Behavior:
				inOwner = false
			if not objTree.IterNext(it):
				break
		ox = objTree.GetValue(par,0)
		if (mat = ox as kri.Material) and inMat:
			for unit in mat.unit:
				objTree.AppendValues(par,unit)
			for meta in mat.metaList:
				objTree.AppendValues(par,meta)
		if (rec = ox as kri.ani.data.Record) and inAni:
			for ch in rec.channels:
				objTree.AppendValues(par,ch)
		if (vs = ox as kri.vb.Storage) and inStore:
			for vat in vs.vbo:
				for ai in vat.Semant:
					objTree.AppendValues(par,AtBox(ai))
		if (own = ox as kri.part.Manager) and inOwner:
			for beh in own.behos:
				objTree.AppendValues(par,beh)
		objView.ExpandRow( args.Path, true )

	
	#--------------------
	# visuals

	private def objFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		obj = model.GetValue(iter,0)
		text = obj.GetType().ToString()
		icon = 'file'
		iNoded = obj as kri.INoded
		if iNoded and iNoded.Node:
			text = iNoded.Node.name
		# select icon and tet
		if obj isa kri.Camera:
			icon = 'fullscreen'
		if obj isa kri.Light:
			icon = 'dialog-info'
		if obj isa kri.Entity:
			icon = 'orientation-portrait'
		if (emi = obj as kri.part.Emitter):
			text = emi.name
			icon = 'about'
		if obj isa kri.part.Manager:
			text = 'manager'
			icon = 'directory'
		if obj isa kri.part.Behavior:
			icon = 'add'
		if obj isa kri.Node:
			text = 'node'
			icon = 'sort-descending'
		if obj isa kri.Skeleton:
			text = 'sleleton'
			icon = 'disconnect'
		if (rec = obj as kri.ani.data.Record):
			text = "${rec.name} (${rec.length})"
			icon = 'cdrom'
		if (chan = obj as kri.ani.data.IChannel):
			icon = 'execute'
			text = chan.Tag
		if (mat = obj as kri.Material):
			text = mat.name
			icon = 'select-color'
		if (mad = obj as kri.meta.Advanced):
			text = mad.Name
			icon = 'color-picker'
		if (mun = obj as kri.meta.AdUnit):
			text = '(empty)'
			icon = 'harddisk'
			if mun.Value:
				text = mun.Value.target.ToString()
		if obj isa kri.vb.Storage:
			text = ('store','mesh')[obj isa kri.Mesh]
			icon = 'dnd-multiple'
		if (box = obj as AtBox):
			text = box.info.name
			icon = 'preferences'
		# set the result
		if (ct = cell as Gtk.CellRendererText):
			ct.Text = text
		if (cp = cell as Gtk.CellRendererPixbuf):
			cp.StockId = 'gtk-'+icon


	#--------------------
	# construction
			
	private def makeWidget() as Gtk.GLWidget:
		context	= config.ask('Context','0')
		#return Gtk.GLWidget()	# for gl-2
		bug = context.EndsWith('d')
		ver = uint.Parse( context.TrimEnd(*'rd'.ToCharArray()) )
		gm = GraphicsMode( ColorFormat(8), 24, 8 )
		conFlags  = GraphicsContextFlags.ForwardCompatible
		if bug:	conFlags |= GraphicsContextFlags.Debug	
		return Gtk.GLWidget(gm,3,ver,conFlags)
	
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
		GLib.Idle.Add( onIdle )
		GLib.ExceptionManager.UnhandledException += onException
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
		filt = Gtk.FileFilter( Name:'kri scenes' )
		filt.AddPattern("*.scene")
		dOpen.AddFilter(filt)
		# make panel
		propertyBook.ShowTabs = false
		objView.AppendColumn( makeColumn() )
		objView.Model = objTree
		objView.CursorChanged	+= onSelectObj
		objView.RowActivated	+= onActivateObj
		camActiveBut.Clicked	+= do(o as object, args as System.EventArgs):
			if not camActiveBut.Active:
				return
			view.cam = curObj as kri.Camera
		entVisibleBut.Clicked	+= do(o as object, args as System.EventArgs):
			ent = curObj as kri.Entity
			ent.visible = entVisibleBut.Active
		aniPlayBut.Clicked		+= do(o as object, args as System.EventArgs):
			parIter = Gtk.TreeIter.Zero
			objTree.IterParent(parIter,curIter)
			pl = objTree.GetValue(parIter,0) as kri.ani.data.Player
			rec = curObj as kri.ani.data.Record
			al.add( kri.ani.data.Anim(pl,rec) )
			statusBar.Push(0, "Animation '${rec.name}' started")
		# add gl widget
		drawBox.Child = gw = makeWidget()
		gw.Initialized		+= onInit
		gw.RenderFrame		+= onFrame
		gw.SizeAllocated	+= onSize
		gw.Visible = true
		# run
		statusBar.Push(0, 'Launched')
		Gtk.Application.Run()
