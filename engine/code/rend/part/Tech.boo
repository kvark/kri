namespace kri.rend.part

import System
import System.Collections.Generic
import kri.shade

#---------	RENDER PARTICLES: TECHNIQUE	--------#

public class Tech( Basic ):
	public final tid	as int
	public static final	Invalid	= (of int:,)
	
	protected def constructor(name as string):
		super()
		tid = kri.Ant.Inst.slotTechniques.getForced(name)
	
	public abstract def construct(pe as kri.part.Emitter) as Smart:
		pass
	protected virtual def update(pe as kri.part.Emitter) as uint:
		return 0
	
	protected override def prepare(pe as kri.part.Emitter, ref nin as uint) as Program:
		m = pe.mat
		return null	if not m
		sa = m.tech[tid]
		if not sa:
			m.tech[tid] = sa = construct(pe)
		return null	if sa == Smart.Fixed
		if pe.techReady[tid] == kri.part.TechState.Unknown:
			ats = List[of int]( sa.gatherAttribs( kri.Ant.Inst.slotParticles, false )).ToArray()
			pat = pe.listAttribs()
			ok = Array.TrueForAll(ats, {a| return a in pat })
			pe.techReady[tid] = (kri.part.TechState.Invalid, kri.part.TechState.Ready)[ok]
		return null	if pe.techReady[tid] == kri.part.TechState.Invalid
		nin = update(pe)
		return sa


#---------	RENDER PARTICLES: META TECH	--------#

public class Meta( Tech ):
	private final lMets		as (string)
	private final geom		as bool
	protected shobs			= List[of Object]()
	protected final dict	= rep.Dict()
	private final factory	= Linker(
		kri.Ant.Inst.slotParticles, dict, kri.Ant.Inst.dict )
	
	public def constructor(name as string, gs as bool, *mets as (string)):
		super(name)
		lMets,geom = mets,gs
		factory.onLink = setup
	
	protected def shade(prefix as string) as void:
		shade( prefix+s	for s in('_v','_f') )
	protected def shade(slis as string*) as void:
		shobs.AddRange( Object.Load(s) for s in slis )
	
	private def setup(sa as Smart) as void:
		sa.add( *kri.Ant.Inst.libShaders )
		sa.add( *shobs.ToArray() )

	public override def construct(pe as kri.part.Emitter) as Smart:
		assert pe.mat and pe.owner
		sl = pe.mat.collect(geom,lMets)
		return Smart.Fixed	if not sl
		return factory.link( sl, pe.owner.dict, pe.mat.dict )
	
	public virtual def onManager(man as kri.part.Manager) as void:
		pass
