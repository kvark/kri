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

	public final col_init	= kri.shade.Collector()
	public final col_update	= kri.shade.Collector()

	private parTotal	= kri.shade.par.Value[of single]('part_total')
	public Ready as bool:
		get: return col_init.prog.Ready and col_update.prog.Ready
	
	public def constructor(num as uint):
		total = num
		dict.var(parTotal)
	
	public def makeStandard(pc as Context) as void:
		#init
		col_init.root = pc.sh_init
		col_init.mets['init'] = kri.shade.DefMethod.Void
		#update
		col_update.root = pc.sh_root
		col_update.extra.Add( pc.sh_tool )
		col_update.mets['reset']	= kri.shade.DefMethod.Float
		col_update.mets['update']	= kri.shade.DefMethod.Float


	public def init(pc as Context) as void:
		if data:
			col_init.prog.clear()
			col_update.prog.clear()
		# collect shaders
		col_init	.absorb[of beh.Basic](behos)
		col_update	.absorb[of beh.Basic](behos)
		# collect attributes
		sem = List[of kri.vb.attr.Info]()
		for b in behos:
			sem.AddRange( b.semantics )
			b.link(dict)
		init(sem,total)
		# link
		for col in (col_init,col_update):
			col.compose( sem, kri.Ant.Inst.slotParticles, dict, kri.Ant.Inst.dict )
	
	public def draw() as void:
		GL.DrawArrays( BeginMode.Points, 0, total )
	
	protected def process(pe as Emitter, col as kri.shade.Collector) as bool:
		assert pe.data
		va.bind()
		return false	if not pe.prepare()
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		col.prog.use()
		using kri.Discarder(true), tf.catch():
			draw()
		if not 'Debug':
			GL.Finish()
			#assert tf.result() == total
			ar = array[of single](total*6)
			pe.va.bind()
			pe.data.read(ar)
		return true

	protected def swapData(pe as Emitter) as void:
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
	public def init(pe as Emitter) as bool:
		return process(pe, col_init)
	public def tick(pe as Emitter) as bool:
		swapData(pe)
		return process(pe, col_update)
