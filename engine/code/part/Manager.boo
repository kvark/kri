namespace kri.part

import System.Collections.Generic
import OpenTK.Graphics.OpenGL

#---------------------------------------#
#	ABSTRACT PARTICLE MANAGER			#
#---------------------------------------#

public class Manager(DataHolder):
	private final tf	= kri.TransFeedback(1)
	private final prog_init		= kri.shade.Smart()
	private final prog_update	= kri.shade.Smart()
	private final factory	= kri.shade.Linker( kri.Ant.Inst.slotParticles )
	
	public onUpdate	as callable(kri.Entity)	= null
	public final behos	= List[of Behavior]()
	public final dict	= kri.shade.rep.Dict()
	public final total	as uint
	public final shaders	= List[of kri.shade.Object]()
	public sh_born		as kri.shade.Object	= null

	private parTotal	= kri.shade.par.Value[of single]()
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num
		dict.add('part_total', parTotal)

	private def collect(type as string, method as string, inter as string, oper as string, end as string) as kri.shade.Object:
		names = [b.getMethod(method+'_') for b in behos]
		names.Remove(null)
		decl = join("${type} ${n};\n"	for n in names)
		body = join( oper+n				for n in names)
		all = "#version 130\n${decl}\n${type} ${method}()\t{${inter}${body}${end};\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)
			
		
	public def init(pc as Context) as void:
		sl = kri.Ant.Inst.slotParticles
		def id2out(id as int) as string:
			return 'to_' + sl.Name[id]
		sem = List[of kri.vb.attr.Info]()
		sem.Add( kri.vb.attr.Info(
			slot:pc.at_sys, size:3,
			type:VertexAttribPointerType.Float ))

		sh_init = collect('void', 'init', '', ";\n\t", '')
		sh_reset = collect('void', 'reset', '', ";\n\t", '')
		sh_update = collect('float', 'update', 'float r=1.0', ";\n\tr*= ", ";\n\treturn r")
		out_names = List[of string]()
		out_names.Add( id2out( pc.at_sys ) )
		for b in behos:
			for at in b.semantics:
				out_names.Add( id2out(at.slot) )
				sem.Add( at )
			b.link(dict)
			prog_init.add( b.sh )
			prog_update.add( b.sh )
		
		# has to be after behaviors
		init(sem,total)
		assert sh_born

		prog_init.add('quat')
		prog_init.add( sh_init, pc.v_init )
		tf.Setup( prog_init, false, *out_names.ToArray() )
		prog_init	.link( sl, dict, kri.Ant.Inst.dict )
		
		prog_update.add( *shaders.ToArray() )
		prog_update.add('quat')
		prog_update.add( sh_reset, sh_update, sh_born, pc.sh_root )
		tf.Setup( prog_update, false, *out_names.ToArray() )
		prog_update	.link( sl, dict, kri.Ant.Inst.dict )
	
	private def process(pe as Emitter, prog as kri.shade.Program) as void:
		onUpdate( pe.obj )	if onUpdate
		pe.init( data.semantics, total )	if not pe.data
		va.bind()
		tf.Bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		prog.use()
		using kri.Discarder(true), tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, total )
		if 'Debug':
			ar = array[of single](40)
			pe.data.read(ar)
			ar[0] = 0f

	public def reset(pe as Emitter) as void:
		process(pe, prog_init)

	public def tick(pe as Emitter) as void:
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
		process(pe, prog_update)