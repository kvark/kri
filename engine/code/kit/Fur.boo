namespace kri.kit.fur

import System
import OpenTK.Graphics.OpenGL

//-----------	Entity Tag	-----------------//

public class Tag(kri.ITag):
	pass

//-----------	Maintaining context	-----------------//

public class Context:
	public static final ats			= array(
		kri.Ant.Inst.slotAttributes.getForced('fur_'+s) for s in ('pos','vel'))
	public final d = kri.shade.rep.Dict()
	# parameters
	public final pShellCoef	= kri.shade.par.Value[of single]()
	public final pLength	= kri.shade.par.Value[of single]()
	
	public def constructor():
		d.add('shell_kf',	pShellCoef)

	public static def prepare(e as kri.Entity) as kri.vb.Attrib:
		assert not e.seTag[of Tag]()
		e.tags.Add( Tag() )
		vat = kri.vb.Attrib()
		ai = kri.vb.attr.Info(size:3, type:VertexAttribPointerType.Float, integer:false)
		vm = (null if e.mesh.find(ats[0]) else kri.vb.Attrib())
		for slot in ats:
			assert not e.find(ats[0])
			ai.slot = slot
			vat.semantics.Add(ai)
			vm.semantics.Add(ai) if vm
		vat.initUnits( e.mesh.nVert )
		e.vbo.Add(vat)
		if vm:
			vm.initUnits( e.mesh.nVert )
			e.mesh.vbo.Add(vm)
		return vat


//-----------	Meta data with settings	-----------------//

public class Meta( kri.meta.Hermit ):
	private final fc	as Context
	public shells	as int		= 0
	public length	as single	= 0f
	# methods
	public def constructor(fcon as Context):
		fc = fcon
	#public override def apply() as void:
	#	fc.pShellCoef.Value = 1f / shells
	#	fc.pLength.Value = length


//-----------	Updating physics using TF	-----------------//

public class Update( kri.rend.Basic ):
	private final tf	= kri.TransFeedback()
	private final sa	= kri.shade.Smart()
	private final va	= kri.vb.Array()
	
	public def constructor(fc as Context):
		super(false)
		tf.setup(sa, false, 'to_pos','to_vel')
		sa.add('quat', '/fur/update_v')
		sa.link(kri.Ant.Inst.slotAttributes, fc.d)
	
	public override def process(con as kri.rend.Context) as void:
		va.bind()
		using kri.Discarder():
			for e in kri.Scene.Current.entities:
				fp = e.seTag[of Tag]()
				continue	if not fp
				x = e.find( Context.ats[0] )
				y = e.mesh.find( Context.ats[0] )
				# swap with mesh
				e.swap(x,y)
				e.mesh.swap(y,x)
				# bind
				tf.bind(y)
				x.attribAll()
				kri.Ant.Inst.params.modelView.activate( e.node )
				# draw
				sa.use()
				e.mesh.draw(tf)


//-----------	Drawing (per light?)	-----------------//

public class Draw( kri.rend.tech.Meta ):
	private lit	as kri.Light	= null
	# init
	public def constructor(fc as Context):
		super('fur', ('diffuse','specular','fur'), '/fur/draw')
		dict.attach( fc.d )
	# prepare
	protected override def getUpdate(mat as kri.Material) as callable() as int:
		metaFun = super(mat)
		curLight = lit
		return def() as int:
			curLight.apply()
			metaFun()
			return (mat.Meta['fur'] as Meta).shells
	# work	
	public override def process(con as kri.rend.Context) as void:
		con.activate(true, 0f, false)
		drawScene()
