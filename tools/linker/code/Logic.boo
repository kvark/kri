namespace linker

public class Logic:
	private	final	config	= kri.lib.Config('kri.conf')
	private final	options	= kri.lib.OptionReader(config)
	public	final	treeShader	= Gtk.TreeStore(object)
	public	final	treeInfo	= Gtk.TreeStore(object)
