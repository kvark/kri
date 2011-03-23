namespace kri.rend.tech


public class Basic( kri.rend.Basic ):
	public	final tid	as int		# technique ID
	protected def constructor(name as string):
		tid = kri.Ant.Inst.techniques.create(name)
	def destructor():
		core = kri.Ant.Inst
		core.techniques.delete(tid)	if core
	protected def attribs(local as bool, e as kri.Entity, *ats as (int)) as bool:
		if e.va[tid] == kri.vb.Array.Default:
			return false
		assert not 'supported'
		if e.va[tid]:	e.va[tid].bind()
		#elif not e.enable(local,tid,ats):
		#	e.va[tid] = kri.vb.Array.Default
		#	return false
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
	protected final dict	= kri.shade.par.Dict()
	private final factory	= kri.shade.Linker(dict)
	
	protected def constructor(name as string, gs as bool, outs as (string), *mets as (string)):
		super(name)
		lMets,lOuts = mets,outs
		geom = gs
		factory.onLink = onLink
	
	protected def shade(prefix as string) as void:
		shade( prefix+s for s in ('_v','_f') )
	protected def shade(slis as string*) as void:
		shobs.Extend( kri.shade.Object.Load(s) for s in slis )
	
	private virtual def onLink(sa as kri.shade.Mega) as void:
		if lOuts:
			sa.fragout( *lOuts )
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( *shobs.ToArray() )

	public override def construct(mat as kri.Material) as kri.shade.Bundle:
		sl = mat.collect(geom,lMets)
		if not sl:
			return kri.shade.Bundle.Empty
		return factory.link( sl, mat.dict )
