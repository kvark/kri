namespace linker

import System.Collections.Generic
import OpenTK.Graphics.OpenGL

public class Logic( System.IDisposable ):
	private	final	config	= kri.lib.Config('kri.conf')
	private final	options	= kri.lib.OptionReader(config)
	private	final	gameWindow	= OpenTK.GameWindow(1,1, options.genMode(0,0))
	private	final	ant 		= kri.Ant(config,true,false)
	public	final	treeShader	= Gtk.TreeStore(*( string, object ))
	public	final	treeInfo	= Gtk.TreeStore(*( string, ))
	public	final	bu			= kri.shade.Bundle()
	private	final	entry		= Dictionary[of ShaderType,Gtk.TreeIter]()
	

	public def constructor():
		gameWindow.Visible = false
		entry[ShaderType.VertexShader]		= treeShader.AppendValues('Vertex:',null)
		entry[ShaderType.GeometryShader]	= treeShader.AppendValues('Geometry:',null)
		entry[ShaderType.FragmentShader]	= treeShader.AppendValues('Fragment:',null)
	
	def System.IDisposable.Dispose() as void:
		(gameWindow as System.IDisposable).Dispose()
	
	public def addShader(str as string) as bool:
		type = kri.shade.Object.Type(str)
		iter = Gtk.TreeIter.Zero
		if entry.TryGetValue(type,iter):
			treeShader.AppendValues(iter,str,null)
			return true
		return false
	
	public def link() as bool:
		treeInfo.Clear()
		eAtr		= treeInfo.AppendValues('Attributes:')
		eUni		= treeInfo.AppendValues('Uniforms:')
		#eRez		= treeInfo.AppendValues('Results:')
		bu.clear()
		for data in entry:
			it = Gtk.TreeIter()
			rez = treeShader.IterChildren( it, data.Value )
			while rez:
				str = treeShader.GetValue(it,0) as string
				text = kri.shade.Code.Read(str)
				sob = kri.shade.Object( data.Key, str, text )
				bu.shader.add(sob)
				treeShader.SetValue(it,1,sob)
				rez = treeShader.IterNext(it)
		bu.link()
		if bu.LinkFail:
			return false
		sa = bu.shader
		# read attribs
		for atr in sa.attribs:
			if string.IsNullOrEmpty(atr.name):
				continue
			str = "${atr.type} ${atr.name}"
			if atr.size>1:	str += "[${atr.size}]"
			treeInfo.AppendValues(eAtr,str)
		# read uniforms
		for uni in sa.uniforms:
			str = "${uni.type} ${uni.name}"
			if uni.size>1:	str += "[${uni.size}]"
			treeInfo.AppendValues(eUni,str)
		# read outputs
		return true
	
	public def remove(tp as Gtk.TreePath) as void:
		par = it = Gtk.TreeIter()
		treeShader.GetIter(it,tp)
		if treeShader.IterParent(par,it):
			treeShader.Remove(it)
