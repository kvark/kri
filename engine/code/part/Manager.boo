namespace kri.part

import System.Collections.Generic
import OpenTK.Graphics.OpenGL


#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager(DataHolder):
	protected final tf	= kri.TransFeedback(1)
	protected final prog_init	= kri.shade.Smart()
	protected final prog_update	= kri.shade.Smart()
	private final factory	= kri.shade.Linker( kri.Ant.Inst.slotParticles )
	
	public final behos	= List[of beh.Basic]()
	public final dict	= kri.shade.rep.Dict()
	public final total	as uint
	public final shaders	= List[of kri.shade.Object]()
	public sh_root		as kri.shade.Object	= null

	private parTotal	= kri.shade.par.Value[of single]('part_total')
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num
		dict.var(parTotal)

	private def collect(type as string, method as string, val as string, oper as string) as kri.shade.Object:
		names = [ b.getMethod(method+'_') for b in behos ]
		names.RemoveAll({n| return string.IsNullOrEmpty(n) })
		# easy uniqueness check
		d2 = Dictionary[of string,bool]()
		for n in names:	d2.Add(n,true)
		# gather to the new code
		decl = join("\n${type} ${n};"	for n in names)
		if string.IsNullOrEmpty(oper) or string.IsNullOrEmpty(val):
			body = join("\n\t${n};"		for n in names)
		else:
			help = join("\n\tr${oper}= ${n};"	for n in names)
			body = "\n\t${type} r= ${val};${help}\n\treturn r;"
		all = "#version 130\n${decl}\n\n${type} ${method}()\t{${body}\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)

	public def init(pc as Context) as (string):
		if data:
			prog_init.clear()
			prog_update.clear()
		sl = kri.Ant.Inst.slotParticles
		sem = List[of kri.vb.attr.Info]()

		sh_init		= collect('void','init',	null,null)
		sh_reset	= collect('float','reset',	'1.0','*')
		sh_update	= collect('float','update',	'1.0','*')
		for b in behos:
			sem.AddRange( b.semantics )
			b.link(dict)
			prog_init.add( b.sh )
			prog_update.add( b.sh )
		
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
	