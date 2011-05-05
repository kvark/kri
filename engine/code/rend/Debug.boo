namespace kri.rend.debug

import System
import kri.shade


#---------	RENDER TEXTURE LAYER		--------#

public class Map( kri.rend.Basic ):
	private	final bu	= Bundle()
	public	final layer	= par.Value[of single]('layer')
	
	public def constructor(depth as bool, cube as bool, id as int, t as par.IBase[of kri.buf.Texture]):
		layer.Value = 1f * id
		name = ''
		if depth:
			name = ('show_depth','copy_cube')[cube]
		else:
			name = ('copy','copy_ar')[id>=0]
		bu.shader.add( '/copy_v', "/${name}_f" )
		d = kri.shade.par.Dict()
		d.unit('input',t)
		d.var(layer)
		bu.dicts.Add(d)
	
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate(false)
		kri.Ant.inst.quad.draw(bu)


public class MapDepth( Map ):
	public final pt	as par.Texture
	public def constructor():
		p2 = par.Texture(null)
		super(true,false,-1,p2)
		pt = p2
	public override def process(con as kri.rend.link.Basic) as void:
		pt.Value = con.Depth
		super(con)


#---------	RENDER DEBUG ATTRIBUTE		--------#

public class Attrib( kri.rend.Basic ):
	private final bu	= kri.shade.Bundle()
	private final va	= kri.vb.Array()
	public def constructor():
		bu.shader.add( '/attrib_v', '/color_f' )
		bu.shader.add( *kri.Ant.Inst.libShaders )
	public override def process(con as kri.rend.link.Basic) as void:
		scene = kri.Scene.Current
		if not scene:	return
		con.activate( con.Target.Same, 0f, true )
		con.ClearColor()
		con.ClearDepth(1f)
		for e in scene.entities:
			kri.Ant.Inst.params.activate(e)
			e.render(va,bu)
