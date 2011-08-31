namespace linker

public class GladeApp:
	[Glade.Widget]	window			as Gtk.Window
	[Glade.Widget]	butAction		as Gtk.Button
	[Glade.Widget]	viewShader		as Gtk.TreeView
	[Glade.Widget]	viewInfo		as Gtk.TreeView
	
	private	final	logic			= Logic()

	#--------------------	
	# signals
	
	public def onException(args as GLib.UnhandledExceptionArgs) as void:
		args.ExitApplication = true
	
	public def onInit(o as object, args as System.EventArgs) as void:
		#logic.init()
		return
	
	public def onDelete(o as object, args as Gtk.DeleteEventArgs) as void:
		#logic.quit()
		Gtk.Application.Quit()
	
	public def onButAction(o as object, args as System.EventArgs) as void:
		return
	
	public def onSelectShader(o as object, args as System.EventArgs) as void:
		curIter = Gtk.TreeIter()
		#if not objView.Selection.GetSelected(curIter):
		#	return
	
	public def onActivateObj(o as object, args as Gtk.RowActivatedArgs) as void:
		return

	#--------------------
	# construction
	
	public def constructor():
		# load scheme
		GLib.ExceptionManager.UnhandledException += onException
		xml = Glade.XML('scheme/main.glade', 'window', null)
		xml.Autoconnect(self)
		window.DeleteEvent	+= onDelete
		butAction.Clicked	+= onButAction
		# make shader view
		viewShader.AppendColumn('Shaders:', Gtk.CellRendererText(), object)
		viewShader.Model = logic.treeShader
		viewShader.CursorChanged	+= onSelectShader
		# make info view
		viewInfo.AppendColumn('Information:', Gtk.CellRendererText())
		viewInfo.Model = logic.treeInfo
		# start
		window.Show()
