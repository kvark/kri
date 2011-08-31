namespace linker

public class Logic( System.IDisposable ):
	private	final	config	= kri.lib.Config('kri.conf')
	private final	options	= kri.lib.OptionReader(config)
	private	final	gameWindow	= OpenTK.GameWindow(1,1, options.genMode(0,0))
	private	final	ant 		= kri.Ant(config,true,false)
	public	final	treeShader	= Gtk.TreeStore(object)
	public	final	treeInfo	= Gtk.TreeStore(object)
	
	public def constructor():
		gameWindow.Visible = false
	
	def System.IDisposable.Dispose() as void:
		(gameWindow as System.IDisposable).Dispose()
