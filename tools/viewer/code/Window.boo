namespace viewer

public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	drawBox			as Gtk.Container
	[Glade.Widget]	statusBar		as Gtk.Statusbar
	[Glade.Widget]	toolBar			as Gtk.Toolbar
	[Glade.Widget]	butClear		as Gtk.ToolButton
	[Glade.Widget]	butOpen			as Gtk.ToolButton
	[Glade.Widget]	butDraw			as Gtk.ToggleToolButton
	[Glade.Widget]	butPlay			as Gtk.ToolButton
	[Glade.Widget]	butProfile		as Gtk.ToolButton
	[Glade.Widget]	butStereo		as Gtk.ToggleToolButton
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
	[Glade.Widget]	entCleanBut		as Gtk.Button
	[Glade.Widget]	entVisibleBut	as Gtk.ToggleButton
	[Glade.Widget]	entFrameVisBut	as Gtk.ToggleButton
	[Glade.Widget]	recNumLabel		as Gtk.Label
	[Glade.Widget]	recPlayBut		as Gtk.Button
	[Glade.Widget]	emiStartBut		as Gtk.Button
	[Glade.Widget]	renderCombo		as Gtk.ComboBox
	
	private	final	log		= kri.lib.Journal()
	private	final	config	= kri.lib.Config('kri.conf')
	private final	options	= kri.lib.OptionReader(config)
	private final	fps		= kri.FpsCounter(1.0,'Viewer')
	private	final	view	= kri.ViewScreen()
	private	final	al		= kri.ani.Scheduler()
	private	final	objTree	= Gtk.TreeStore(object)
	private	final	dOpen	as Gtk.FileChooserDialog
	private final	dialog	as Gtk.MessageDialog
	public	final	gw		as Gtk.GLWidget
	private	vProxy	as kri.IView	= null
	private rset	as RenderSet	= null
	private	curObj	as object		= null
	private	curIter	= Gtk.TreeIter.Zero
	
	private def showMessage(mType as Gtk.MessageType, text as string) as void:
		dialog.MessageType = mType
		dialog.Text = text
		dialog.Run()
		dialog.Hide()
	
	private def flushJournal() as bool:
		all = log.flush()
		if not all: return false
		gw.Visible = false
		showMessage( Gtk.MessageType.Warning, all )
		gw.Visible = true
		return true
	
	private def resetScene() as void:
		if not view.scene:	return
		for e in view.scene.entities:
			e.frameVisible.Clear()
		#for l in view.scene.lights:
		#	l.depth = null
	
	private def playRecord(it as Gtk.TreeIter) as kri.ani.data.Record:
		par = Gtk.TreeIter.Zero
		objTree.IterParent(par,it)
		pl = objTree.GetValue(par,0) as kri.ani.data.Player
		rec = objTree.GetValue(it,0) as kri.ani.data.Record
		al.add( kri.ani.data.Anim(pl,rec) )
		return rec
	
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
			#ent.tags.Add( kri.rend.box.Tag() )
			it = addObject(ent)
			addObject( it, ent.store )
			for tag in ent.tags:
				td = tag as kri.ITagData
				if td:	addObject(it,td.Data)
		for par in view.scene.particles:
			it = addObject(par)
			addObject( it, par.owner )
	
	public def load(path as string) as void:
		rset.grCull.con.reset()
		pos = path.LastIndexOfAny((char('/'),char('\\')))
		fdir = path.Substring(0,pos)
		# load scene
		kri.Ant.Inst.loaders.materials.prefix = fdir
		kri.load.image.Basic.Compressed = true
		loader = kri.load.Native()
		at = loader.read(path)
		view.scene = at.scene
		rset.grCull.con.fillScene(at.scene)
		if at.scene.cameras.Count:	# set camera
			view.cam = at.scene.cameras[0]
		# notify
		updateList()
		flushJournal()
		statusBar.Push(0, 'Loaded ' + path.Substring(pos+1) )
	
	public def playAll() as void:
		al.clear()
		used = List[of object]()
		tw = TreeWalker(objTree)
		while tw.next():
			ob = tw.Value
			if ob as kri.ani.data.Record:
				par = tw.Parent
				if par not in used:
					used.Add(par)
					playRecord( tw.Iter )
			emi = ob as kri.part.Emitter
			if emi:
				emi.filled = false
				al.add(emi)
		statusBar.Push(0, 'Started all scene animations')
	
	public def setDraw() as void:
		butDraw.Active = true
	
	public def setPipe(str as string) as int:
		cur = 0
		it as Gtk.TreeIter
		md = renderCombo.Model
		rez = md.GetIterFirst(it)
		while rez:
			sx = md.GetValue(it,0) as string
			if sx == str:
				renderCombo.Active = cur
				return cur
			rez = md.IterNext(it)
			++cur
		kri.lib.Journal.Log("Viewer: pipeline '${str}' not found");
		return -1

	public def getSceneStats() as string:
		if not view.scene: return ''
		total = view.scene.entities.Count
		active = view.countVisible()
		return ", ${active}/${total} visible"

	#--------------------	
	# signals
	
	public def onException(args as GLib.UnhandledExceptionArgs) as void:
		args.ExitApplication = true
		System.IO.File.WriteAllText( 'exception.txt', args.ExceptionObject.ToString() )
	
	public def onInit(o as object, args as System.EventArgs) as void:
		samples = byte.Parse(config.ask('InnerSamples','0'))
		ant = kri.Ant( config, options.debug, options.gamma )
		eLayer	= support.layer.Extra()
		eSkin	= support.skin.Extra()
		eCorp	= support.corp.Extra()
		eMorph	= support.morph.Extra()
		ant.extensions.AddRange((of kri.IExtension:eLayer,eSkin,eCorp,eMorph))
		ant.anim = al
		rset = RenderSet( true, samples, eCorp.con )
		rset.grDeferred.rBug.layer = -1
		vProxy = support.stereo.Proxy(view,0.02f,0.9f)
		gw.QueueResize()
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		rset = null
		(kri.Ant.Inst as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onIdle() as bool:
		if butDraw.Active:
			gw.QueueDraw()
		elif window.Title != fps.title:
			window.Title = fps.title
		return true
	
	public def onFrame(o as object, args as System.EventArgs) as void:
		core = kri.Ant.Inst
		if not core:	return
		core.update(1)
		mv = (view,vProxy)[butStereo.Active]
		mv.update()
		if butDraw.Active and fps.update(core.Time):
			window.Title = fps.gen() + getSceneStats()
		flushJournal()
	
	public def onSize(o as object, args as Gtk.SizeAllocatedArgs) as void:
		r = args.Allocation
		mv = (view,vProxy)[vProxy!=null]
		mv.resize( r.Width, r.Height )
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
		load( dOpen.Filename )
		gw.QueueDraw()
	
	public def onButPlay(o as object, args as System.EventArgs) as void:
		playAll()
	
	public def onSelectObj(o as object, args as System.EventArgs) as void:
		curIter = Gtk.TreeIter()
		if not objView.Selection.GetSelected(curIter):
			return
		curObj = obj = objTree.GetValue(curIter,0)
		propertyBook.Page = 0
		if (ent = obj as kri.Entity):
			entVisibleBut.Active = ent.visible
			entFrameVisBut.Active = ent.VisibleCam
			propertyBook.Page = 1
		if obj isa kri.Node:
			propertyBook.Page = 2
		if obj isa kri.Material:
			propertyBook.Page = 3
		if (cam = obj as kri.Camera):
			camFovLabel.Text = 'Fov: ' + cam.fov
			camAspectLabel.Text = 'Aspect: ' + cam.aspect
			camActiveBut.Active = view.cam == cam
			propertyBook.Page = 4
		if obj isa kri.Light:
			propertyBook.Page = 5
		if (rec = obj as kri.ani.data.Record):
			recNumLabel.Text = 'Channels: ' + rec.channels.Count
			propertyBook.Page = 6
		if (meta = obj as kri.meta.Advanced):
			metaUnitLabel.Text = 'Unit: ' + meta.Unit
			metaShaderLabel.Text = ''
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
		if obj isa kri.part.Emitter:
			propertyBook.Page = 10
	
	public def onActivateObj(o as object, args as Gtk.RowActivatedArgs) as void:
		par = it = Gtk.TreeIter()
		objTree.GetIter(par,args.Path)
		rez = objTree.IterChildren(it,par)
		while rez:
			ox = objTree.GetValue(it,0)
			if	(ox isa kri.meta.AdUnit) or (ox isa kri.meta.Advanced) or\
				(ox isa kri.ani.data.IChannel) or (ox isa AtBox) or (ox isa kri.part.Behavior):
				rez = objTree.Remove(it)
			else:
				rez = objTree.IterNext(it)
		ox = objTree.GetValue(par,0)
		if (mat = ox as kri.Material):
			for unit in mat.unit:
				objTree.AppendValues(par,unit)
			for meta in mat.metaList:
				objTree.AppendValues(par,meta)
		if (rec = ox as kri.ani.data.Record):
			for ch in rec.channels:
				objTree.AppendValues(par,ch)
		if (vs = ox as kri.vb.Storage):
			for vat in vs.buffers:
				for ai in vat.Semant:
					objTree.AppendValues(par,AtBox(ai))
		if (own = ox as kri.part.Manager):
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
			text = "[${chan.ElemId}] ${chan.Tag}"
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
		gm = options.genMode(32,24)
		fl = options.genFlags()
		return Gtk.GLWidget( gm, options.verMajor, options.verMinor, fl )
	
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
		GLib.Idle.Add( onIdle )
		GLib.ExceptionManager.UnhandledException += onException
		# load scheme
		xml = Glade.XML('scheme/main.glade', 'window', null)
		xml.Autoconnect(self)
		window.DeleteEvent	+= onDelete
		dialog = Gtk.MessageDialog( window, Gtk.DialogFlags.Modal,
			Gtk.MessageType.Warning, Gtk.ButtonsType.Ok, null )
		dialog.WidthRequest = 400
		dialog.HeightRequest = 300
		# make toolbar
		butClear.Clicked	+= onButClear
		butOpen.Clicked 	+= onButOpen
		butPlay.Clicked		+= onButPlay
		butProfile.Clicked	+= do(o as object, args as System.EventArgs):
			showMessage( Gtk.MessageType.Info, rset.rMan.genReport() )
		dOpen = Gtk.FileChooserDialog('Select KRI scene to load:',
			window, Gtk.FileChooserAction.Open )
		dOpen.AddButton('Load',0)
		filt = Gtk.FileFilter( Name:'KRI Scenes' )
		filt.AddPattern('*.scene')
		dOpen.AddFilter(filt)
		# make panel
		propertyBook.ShowTabs = false
		objView.AppendColumn( makeColumn() )
		objView.Model = objTree
		objView.CursorChanged	+= onSelectObj
		objView.RowActivated	+= onActivateObj
		camActiveBut.Clicked	+= do(o as object, args as System.EventArgs):
			if not camActiveBut.Active:	return
			view.cam = curObj as kri.Camera
		entCleanBut.Clicked		+= do(o as object, args as System.EventArgs):
			(curObj as kri.Entity).deleteOwnData()
		entVisibleBut.Clicked	+= do(o as object, args as System.EventArgs):
			(curObj as kri.Entity).visible = entVisibleBut.Active
		recPlayBut.Clicked		+= do(o as object, args as System.EventArgs):
			rec = playRecord(curIter)
			statusBar.Push(0, "Animation '${rec.name}' started")
		emiStartBut.Clicked		+= do(o as object, args as System.EventArgs):
			emi = curObj as kri.part.Emitter
			emi.filled = false
			al.remove(emi)
			emi.filled = false
			al.add(emi)
			statusBar.Push(0, "Particle '${emi.name}' started")
		renderCombo.Changed		+= do(o as object, args as System.EventArgs):
			str = renderCombo.ActiveText
			view.ren = rset.gen(str)
			resetScene()
			statusBar.Push(0, 'Pipeline switched to '+str)
			view.updateSize()
			gw.QueueDraw()
		# add gl widget
		drawBox.Child = gw = makeWidget()
		gw.Initialized		+= onInit
		gw.RenderFrame		+= onFrame
		gw.SizeAllocated	+= onSize
		gw.Visible = true
		# run
		statusBar.Push(0, 'Launched')
