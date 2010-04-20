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
	public sh_born		as kri.shade.Object	= null

	private parTotal	= kri.shade.par.Value[of single]('part_total')
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num
		dict.var(parTotal)

	private def collect(type as string, method as string, inter as string, oper as string, end as string) as kri.shade.Object:
		names = [ b.getMethod(method+'_') for b in behos ]
		names.RemoveAll({n| return string.IsNullOrEmpty(n) })
		# easy uniqueness check
		d2 = Dictionary[of string,bool]()
		for n in names:	d2.Add(n,true)
		# gather to the new code
		decl = join("${type} ${n};\n"	for n in names)
		body = join( oper+n				for n in names)
		all = "#version 130\n${decl}\n${type} ${method}()\t{${inter}${body}${end};\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)
	

	public def init(pc as Context) as (string):
		if data:
			prog_init.clear()
			prog_update.clear()	
		sl = kri.Ant.Inst.slotParticles
		sem = List[of kri.vb.attr.Info]()
		tip = ( VertexAttribPointerType.HalfFloat, VertexAttribPointerType.Float )[true]
		sem.Add( kri.vb.attr.Info( slot:pc.at_sys, size:2, type:tip ))

		sh_init		= collect('void', 'init', '', ";\n\t", '')
		sh_reset	= collect('float','reset',	'float r=1.0', ";\n\tr*= ", ";\n\treturn r")
		sh_update	= collect('float','update',	'float r=1.0', ";\n\tr*= ", ";\n\treturn r")
		for b in behos:
			sem.AddRange( b.semantics )
			b.link(dict)
			prog_init.add( b.sh )
			prog_update.add( b.sh )
		
		# has to be after behaviors
		init(sem,total)
		assert sh_born
		out_names = array( 'to_'+sl.Name[at.slot] for at in sem )

		prog_init.add('quat')
		prog_init.add( sh_init, pc.v_init )
		tf.Setup( prog_init, false, *out_names )
		prog_init	.link( sl, dict, kri.Ant.Inst.dict )

		prog_update.add( *shaders.ToArray() )
		prog_update.add('quat')
		prog_update.add( sh_reset, sh_update, sh_born, pc.sh_root )
		tf.Setup( prog_update, false, *out_names )
		prog_update	.link( sl, dict, kri.Ant.Inst.dict )
		return out_names
	
	protected def process(pe as Emitter, prog as kri.shade.Program) as void:
		va.bind()
		return	if not pe.prepare()
		pe.init( data.semantics, total )	if not pe.data
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		prog.use()
		using kri.Discarder(true), tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, total )
		if 'Debug':
			ar = array[of single](20)
			pe.data.read(ar)
			ar[0] = 0f

	public def reset(pe as Emitter) as void:
		process(pe, prog_init)

	protected def swapData(pe as Emitter) as void:
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
	public def tick(pe as Emitter) as void:
		swapData(pe)
		process(pe, prog_update)
	