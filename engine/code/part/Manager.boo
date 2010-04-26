namespace kri.part

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager(DataHolder):
	protected final tf	= kri.TransFeedback(1)
	public final behos	= List[of beh.Basic]()
	public final dict	= kri.shade.rep.Dict()
	public final total	as uint

	#private final factory	= kri.shade.Linker( kri.Ant.Inst.slotParticles )
	public final shaders	= List[of kri.shade.Object]()
	public sh_root		as kri.shade.Object	= null
	protected final prog_init	= kri.shade.Smart()
	protected final prog_update	= kri.shade.Smart()
	
	protected final col_init	= kri.shade.Collector()
	protected final col_update	= kri.shade.Collector()

	private parTotal	= kri.shade.par.Value[of single]('part_total')
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num
		dict.var(parTotal)
		col_init.mets['init'] = kri.shade.DefMethod( type:'void' )
		dm = kri.shade.DefMethod( type:'float', val:'1.0', oper:'*' )
		col_update.mets['reset'] = dm
		col_update.mets['update'] = dm

	public def init(pc as Context) as (string):
		if data:
			prog_init.clear()
			prog_update.clear()
		sl = kri.Ant.Inst.slotParticles
		sem = List[of kri.vb.attr.Info]()
		
		#col_init.absorb[of beh.Basic](behos)
		#col_update.absorb[of beh.Basic](behos)
		sh_init		= col_init.gather('init',behos)
		sh_reset	= col_update.gather('reset',behos)
		sh_update	= col_update.gather('update',behos)
		for b in behos:
			sem.AddRange( b.semantics )
			b.link(dict)
			prog_init.add( b.Shader )
			prog_update.add( b.Shader )
		
		# has to be after behaviors
		init(sem,total)
		assert sh_root
		out_names = array( 'to_'+sl.Name[at.slot] for at in sem )

		prog_init.add('quat')
		prog_init.add( pc.sh_tool, pc.sh_init, sh_init )
		tf.Setup( prog_init, false, *out_names )
		prog_init	.link( sl, dict, kri.Ant.Inst.dict )

		prog_update.add( *shaders.ToArray() )
		prog_update.add('quat')
		prog_update.add( pc.sh_tool, sh_root, sh_reset, sh_update )
		tf.Setup( prog_update, false, *out_names )
		prog_update	.link( sl, dict, kri.Ant.Inst.dict )
		return out_names
	
	public def draw() as void:
		GL.DrawArrays( BeginMode.Points, 0, total )
	
	protected def process(pe as Emitter, prog as kri.shade.Program) as bool:
		assert pe.data
		va.bind()
		return false	if not pe.prepare()
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		prog.use()
		using kri.Discarder(true), tf.catch():
			draw()
		if not 'Debug':
			pe.va.bind()
			ar = array[of single](total*8)
			pe.data.read(ar)
		return true

	protected def swapData(pe as Emitter) as void:
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
	public def init(pe as Emitter) as bool:
		return process(pe, prog_init)
	public def tick(pe as Emitter) as bool:
		swapData(pe)
		return process(pe, prog_update)
	