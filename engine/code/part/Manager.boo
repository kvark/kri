namespace kri.part

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager(DataHolder):
	protected final tf	= kri.TransFeedback(1)
	public final behos	= List[of Behavior]()
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
	
	public def makeHair(pc as Context) as void:
		# collectors
		col_init.mets['init']		= kri.shade.DefMethod.Void
		col_update.mets['update']	= kri.shade.DefMethod.Float
		col_init.root	= pc.sh_fur_init
		col_update.root	= pc.sh_fur_root
		if not 'Attrib zero bug workaround':
			b2 = Behavior('/part/fur/dummy')
			kri.Help.enrich( b2, 2, (kri.Ant.Inst.slotParticles.getForced('sys'),), ('sys',) )
			behos.Add(b2)
	
	public def seBeh[of T(Behavior)]() as T:
		for beh in behos:
			bt = beh as T
			return bt	if bt
		return null	as T

	public def init(pc as Context) as void:
		if data:
			col_init.prog.clear()
			col_update.prog.clear()
		# collect shaders
		col_init	.absorb[of Behavior](behos)
		col_update	.absorb[of Behavior](behos)
		# collect attributes
		sem = List[of kri.vb.Info]()
		for b in behos:
			sem.AddRange( b.Semant )
			b.link(dict)
		init(sem,total)
		# link
		for col in (col_init,col_update):
			col.compose( sem, kri.Ant.Inst.slotParticles, dict, kri.Ant.Inst.dict )
	
	public def draw(nin as uint) as void:
		if nin:
			GL.DrawArraysInstanced( BeginMode.Points, 0, total, nin )
		else:
			GL.DrawArrays( BeginMode.Points, 0, total )
	
	protected def process(pe as Emitter, col as kri.shade.Collector) as bool:
		assert pe.data
		va.bind()
		return false	if not pe.prepare()
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		col.prog.use()
		using kri.Discarder(true), tf.catch():
			draw(0)
		if not 'Debug':
			assert tf.result() == total
			ar = array[of single]( total * data.unitSize() >>2 )
			pe.va.bind()
			pe.data.read(ar)
		return true

	protected def swapData(pe as Emitter) as void:
		kri.Help.swap(data, pe.data)
		kri.Help.swap(va, pe.va)
	public def init(pe as Emitter) as bool:
		return process(pe, col_init)
	public def tick(pe as Emitter) as bool:
		swapData(pe)
		return process(pe, col_update)
