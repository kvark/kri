namespace kri.rend.tech


public class Basic( kri.rend.Basic ):
	protected	final tid	as int		# technique ID
	protected def constructor(name as string):
		super(false)
		tid = kri.Ant.Inst.slotTechniques.create(name)
	def destructor():
		kri.Ant.Inst.slotTechniques.delete(tid)
	protected def attribs(local as bool, e as kri.Entity, *ats as (int)) as bool:
		return false	if e.va[tid] == kri.vb.Array.Default
		if e.va[tid]:	e.va[tid].bind()
		elif not e.enable(local,tid,ats):
			e.va[tid] = kri.vb.Array.Default
			return false
		return true


#public class Object(Basic):
#	protected final sa	= kri.shade.Smart()
#	protected final va	= kri.vb.Array()


#---------	META TECHNIQUE	--------#

public class Meta(General):
	private final lMets	as (string)
	private final lOuts	as (string)
	private final geom	as bool
	protected shobs			= List[of kri.shade.Object]()
	protected final dict	= kri.shade.rep.Dict()
	private final factory	= kri.shade.Linker(
		kri.Ant.Inst.slotAttributes, dict, kri.Ant.Inst.dict )
	
	protected def constructor(name as string, gs as bool, outs as (string), *mets as (string)):
		super(name)
		lMets,lOuts,geom = mets,outs,gs
		factory.onLink = setup
	
	protected def shade(prefix as string) as void:
		for s in ('_v','_f'):
			shobs.Add( kri.shade.Object(prefix+s) )
	protected def shade(slis as string*) as void:
		shobs.Extend( kri.shade.Object(s) for s in slis )
	
	private def setup(sa as kri.shade.Smart) as void:
		sa.fragout( *lOuts )	if lOuts
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.add( *array(shobs) )

	public override def construct(mat as kri.Material) as kri.shade.Smart:
		sl = mat.collect(geom,lMets)
		return kri.shade.Smart.Fixed	if not sl
		return factory.link( sl, mat.dict )
