namespace kri.rend.debug

import System
import kri.shade


#---------	RENDER TEXTURE LAYER		--------#

public class Map( kri.rend.Basic ):
	private final sa	= Smart()
	public final layer	= par.Value[of single]('layer')
	
	public def constructor(depth as bool, cube as bool, id as int, t as par.IBase[of kri.buf.Texture]):
		name = ''
		if depth:
			name = ('show_depth','copy_cube')[cube]
		else:
			name = ('copy','copy_ar')[id>=0]
		sa.add( '/copy_v', "/${name}_f" )
		layer.Value = 1f * id
		dict = kri.shade.rep.Dict()
		dict.unit( 'input', t )
		dict.var(layer)
		sa.link( kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
	
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate(false)
		sa.use()
		kri.Ant.inst.quad.draw()


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
	private final sa	= kri.shade.Smart()
	private final va	= kri.vb.Array()
	public def constructor():
		sa.add( '/attrib_v', '/attrib_f' )
		sa.add( *kri.Ant.Inst.libShaders )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	public override def process(con as kri.rend.link.Basic) as void:
		con.activate( con.Target.Same, 0f, true )
		con.ClearColor()
		con.ClearDepth(1f)
		va.bind()
		for e in kri.Scene.Current.entities:
			for a in (kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat):
				rez = e.store.bind(a) or e.mesh.bind(a)
				assert rez
			e.mesh.ind.bind()
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.use()
			e.mesh.draw(1)
