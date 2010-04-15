namespace kri.rend.debug

import System
import OpenTK.Graphics.OpenGL
import kri.shade

public class Map( kri.rend.Basic ):
	private final sa	= Smart()
	public final layer	= par.Value[of single]('layer')
	
	public def constructor(depth as bool, t as par.IBase[of kri.Texture]):
		super(false)
		sa.add( 'copy_v', ('copy_f','/show_depth_f')[depth] )
		dict = kri.shade.rep.Dict()
		dict.unit( 'input', t )
		dict.var(layer)
		sa.link( kri.Ant.Inst.slotAttributes, dict )

	public override def process(con as kri.rend.Context) as void:
		con.activate()
		sa.use()
		kri.Ant.inst.emitQuad()


public class MapCube( kri.rend.Basic ):
	private final lit	as kri.Light
	private final sa = kri.shade.Smart()
	public def constructor( l as kri.Light ):
		super(false)
		sa.add( 'copy_v', '/copy_cube_f' )
		sa.link(kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict)
		lit = l
	public virtual def prepare() as void:
		assert 'not ready'
		#u = kri.Ant.Inst.units
		#u.Tex[u.light] = lit.depth
		#lit.depth.bind(u.light)
		kri.Texture.Shadow(false)
		ar = array[of single](4)
		GL.GetTexImage(TextureTarget.TextureCubeMapPositiveZ, 0,
			PixelFormat.DepthComponent, PixelType.Float, ar)
		ar = null
	public override def process(con as kri.rend.Context) as void:
		prepare()	#unit activation
		con.activate()
		sa.use()
		kri.Ant.inst.emitQuad()


/*	#todo: rewrite
public class MapLight( Map ):
	private final lit	as kri.Light
	public def constructor(lay as int, l as kri.Light):
		super( kri.Ant.Inst.units.light, lay )
		lit = l
	public override def prepare() as void:
		u = kri.Ant.Inst.units
		u.Tex[u.light] = lit.depth
		lit.depth.bind(u.light)
		kri.Texture.Shadow(false)
*/		

#---------	RENDER DEBUG ATTRIBUTE		--------#

public class Attrib( kri.rend.Basic ):
	private final sa	= kri.shade.Smart()
	private final va	= kri.vb.Array()
	public def constructor():
		super(false)
		sa.add( '/attrib_v', '/attrib_f' )
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.link( kri.Ant.Inst.slotAttributes, kri.Ant.Inst.dict )
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, true)
		con.ClearColor()
		con.ClearDepth(1f)
		va.bind()
		for e in kri.Scene.Current.entities:
			for a in (kri.Ant.Inst.attribs.vertex, kri.Ant.Inst.attribs.quat):
				rez = e.bind(a) or e.mesh.bind(a)
				assert rez
			e.mesh.ind.bind()
			kri.Ant.Inst.params.modelView.activate( e.node )
			sa.use()
			e.mesh.draw()
