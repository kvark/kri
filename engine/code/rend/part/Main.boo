namespace kri.rend.part

import System
import OpenTK.Graphics.OpenGL


#---------	RENDER PARTICLES BASE		--------#

public class Basic( kri.rend.Basic ):
	public final dTest	as bool
	public final bAdd	as bool
	
	protected def constructor(depth as bool, add as bool):
		super(false)
		dTest,bAdd = depth,add
	protected abstract def prepare(pe as kri.part.Emitter) as kri.shade.Program:
		pass
	public override def process(con as kri.rend.Context) as void:
		if dTest: con.activate(true, 0f, false)
		else: con.activate()
		using blend = kri.Blender(),\
		kri.Section( EnableCap.ClipPlane0 ),\
		kri.Section( EnableCap.VertexProgramPointSize ):
			if bAdd:	blend.add()
			else:		blend.alpha()
			for pe in kri.Scene.Current.particles:
				sa = prepare(pe)
				continue	if not sa
				pe.va.bind()
				return	if not pe.prepare()
				sa.use()
				pe.owner.draw()



#---------	RENDER PARTICLES: SINLE SHADER		--------#

public class Simple( Basic ):
	protected final sa		= kri.shade.Smart()
	private ats	as (int)	= null
	public def constructor(depth as bool, add as bool):
		super(depth,add)
	public override def setup(far as kri.frame.Array) as bool:
		ats = array( sa.gatherAttribs(kri.Ant.Inst.slotParticles) )
		return true
	protected override def prepare(pe as kri.part.Emitter) as kri.shade.Program:
		return sa



#---------	RENDER PARTICLES: TECHNIQUE	--------#

public class Tech( Basic, kri.rend.tech.IConstructor ):
	public final tid	as int
	public static final	Invalid	= (of int:,)
	
	protected def constructor(name as string, add as bool):
		super(true,add)
		tid = kri.Ant.Inst.slotTechniques.getForced(name)
	
	public abstract def construct(m as kri.Material) as kri.shade.Smart:
		pass
	protected override def prepare(pe as kri.part.Emitter) as kri.shade.Program:
		m = pe.mat
		return null	if not m
		sa = m.tech[tid]
		if not sa:
			m.tech[tid] = sa = construct(m)
		return null	if sa == kri.shade.Smart.Fixed
		if pe.techReady[tid] == kri.part.TechState.Unknown:
			ats = array( sa.gatherAttribs( kri.Ant.Inst.slotParticles ))
			pat = pe.listAttribs()
			ok = Array.TrueForAll(ats, {a| return a in pat })
			pe.techReady[tid] = (kri.part.TechState.Invalid, kri.part.TechState.Ready)[ok]
		return null	if pe.techReady[tid] == kri.part.TechState.Invalid
		return sa
