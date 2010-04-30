namespace kri.rend.part

import System
import kri.shade

#---------	RENDER PARTICLES: TECHNIQUE	--------#

public class Tech( Basic, kri.rend.tech.IConstructor ):
	public final tid	as int
	public static final	Invalid	= (of int:,)
	
	protected def constructor(name as string):
		super()
		dTest = true
		tid = kri.Ant.Inst.slotTechniques.getForced(name)
	
	public abstract def construct(m as kri.Material) as Smart:
		pass
	protected override def prepare(pe as kri.part.Emitter) as Program:
		m = pe.mat
		return null	if not m
		sa = m.tech[tid]
		if not sa:
			m.tech[tid] = sa = construct(m)
		return null	if sa == Smart.Fixed
		if pe.techReady[tid] == kri.part.TechState.Unknown:
			ats = array( sa.gatherAttribs( kri.Ant.Inst.slotParticles ))
			pat = pe.listAttribs()
			ok = Array.TrueForAll(ats, {a| return a in pat })
			pe.techReady[tid] = (kri.part.TechState.Invalid, kri.part.TechState.Ready)[ok]
		return null	if pe.techReady[tid] == kri.part.TechState.Invalid
		return sa


#---------	RENDER PARTICLES: META TECH	--------#

public class Meta( Tech ):
	private final lMets		as (string)
	protected shobs			= List[of Object]()
	protected final dict	= rep.Dict()
	private final factory	= Linker(
		kri.Ant.Inst.slotParticles, dict, kri.Ant.Inst.dict )
	
	public def constructor(name as string, *mets as (string)):
		super(name)
		lMets = mets
		factory.onLink = setup
	
	protected def shade(prefix as string) as void:
		for s in ('_v','_f'):
			shobs.Add( Object(prefix+s) )
	protected def shade(slis as string*) as void:
		shobs.Extend( Object(s) for s in slis )
	
	private def setup(sa as Smart) as void:
		sa.add( *kri.Ant.Inst.shaders.gentleSet )
		sa.add( *array(shobs) )

	public override def construct(mat as kri.Material) as Smart:
		sl = mat.collect(lMets)
		return Smart.Fixed	if not sl
		return factory.link( sl, mat.dict )
