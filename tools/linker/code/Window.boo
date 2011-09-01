namespace linker

public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	butAction		as Gtk.Button
	[Glade.Widget]	viewShader		as Gtk.TreeView
	[Glade.Widget]	viewInfo		as Gtk.TreeView
	[Glade.Widget]	textLog			as Gtk.TextView
	
	private	final	logic			= Logic()

	#--------------------	
	# signals
	
	public def onException(args as GLib.UnhandledExceptionArgs) as void:
		args.ExitApplication = true
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		(logic as System.IDisposable).Dispose()
		Gtk.Application.Quit()
	
	public def onButAction(o as object, args as System.EventArgs) as void:
		logic.link()
		onSelectShader(null,null)
		viewInfo.ExpandAll()
	
	public def onSelectShader(o as object, args as System.EventArgs) as void:
		obj as kri.shade.ILogged = logic.bu.shader
		cit = Gtk.TreeIter()
		if viewShader.Selection.GetSelected(cit):
			sob = logic.treeShader.GetValue(cit,1) as kri.shade.Object
			if sob: obj = sob
		textLog.Buffer.Text = obj.Log
	
	public def onActivateShader(o as object, args as Gtk.RowActivatedArgs) as void:
		logic.remove(args.Path)
	
	public def onDragShader(o as object, args as Gtk.DragDataReceivedArgs) as void:
		result = false
		begin = 'file:///'
		str = System.Text.Encoding.ASCII.GetString( args.SelectionData.Data )
		pos = 0
		while not result:
			if not str.StartsWith(begin):	break
			pos += begin.Length
			x = str.LastIndexOf('.glsl')
			if x<0:	break
			result = logic.addShader( str.Substring(pos,x-pos) )
			viewShader.ExpandAll()
		Gtk.Drag.Finish( args.Context, result, false, args.Time )
		
	#--------------------
	# construction
	
	private def shaderFunc(col as Gtk.TreeViewColumn, cell as Gtk.CellRenderer, model as Gtk.TreeModel, iter as Gtk.TreeIter):
		obj = model.GetValue(iter,0) as string
		x = obj.LastIndexOfAny( "/\\".ToCharArray() )
		(cell as Gtk.CellRendererText).Text = obj.Substring(x+1)
	
	public def constructor():
		# load scheme
		GLib.ExceptionManager.UnhandledException += onException
		xml = Glade.XML('scheme/main.glade', 'window', null)
		xml.Autoconnect(self)
		window.DeleteEvent	+= onDelete
		butAction.Clicked	+= onButAction
		# make shader view
		viewShader.Model = logic.treeShader
		rTex = Gtk.CellRendererText()
		col = viewShader.AppendColumn('Shaders:',rTex)
		col.SetCellDataFunc(rTex,shaderFunc)
		viewShader.CursorChanged	+= onSelectShader
		viewShader.RowActivated		+= onActivateShader
		targets = (Gtk.TargetEntry('text/uri-list',cast(Gtk.TargetFlags,0),0),)
		Gtk.Drag.DestSet( viewShader, Gtk.DestDefaults.Drop, targets, Gdk.DragAction.Default )
		viewShader.DragDataReceived	+= onDragShader
		# make info view
		rTex = Gtk.CellRendererText()
		col = viewInfo.AppendColumn('Information:',rTex)
		col.AddAttribute(rTex,'text',0)
		viewInfo.Model = logic.treeInfo
		# start
		window.ShowAll()
