namespace kri.part

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL

private class DataHolder:
	internal data	= kri.vb.Attrib()
	internal va	= kri.vb.Array()

#---------

public class Behavior:
	public final code	as string	= null
	public final semantics = List[of kri.vb.attr.Info]()
	public def constructor(path as string):
		code = kri.shade.Object.readText(path)
	public def getMethod(base as string) as string:
		return ''	if string.IsNullOrEmpty(code)
		pos = code.IndexOf(base)
		p2 = code.IndexOf('()',pos)
		assert pos>=0 and p2>=0
		return code.Substring(pos,p2+2-pos)

#---------

public class Emitter(DataHolder):
	public visible	as bool		= true
	public onUpdate	as callable()	= null
	public final man	as Manager
	public final obj	as kri.Entity
	public final sa		as kri.shade.Smart

	private def init() as void:
		va.bind()
		data.semantics.AddRange( man.data.semantics )
		data.initAll( man.total )
		#man.reset(self)
	public def constructor(pm as Manager, ent as kri.Entity):
		man,obj = pm,ent
		sa = kri.shade.Smart()
		init()
	public def constructor(pe as Emitter):
		man		= pe.man
		obj		= pe.obj
		sa		= pe.sa
		init()
	public def draw() as void:
		va.bind()
		sa.use()
		GL.DrawArrays( BeginMode.Points, 0, man.total )


#---------

public class Context:
	public final	v_init	= kri.shade.Object('/part/init_v')
	public final	g_init	= kri.shade.Object('/part/init_g')
	public final	sh_draw	= kri.shade.Object('/part/draw_v')
	public final	sh_root	= kri.shade.Object('/part/root_v')
	public sh_born	as kri.shade.Object	= null
	public final	dict	= kri.shade.rep.Dict()
	public final	at_sys	= kri.Ant.Inst.slotParticles.getForced('sys')
	public final	pTotal	= kri.shade.par.Value[of single]()
	public def constructor():
		dict.add('part_total', pTotal)


#---------

public class Manager(DataHolder):
	private final tf	= kri.TransFeedback()
	private final prog_init		= kri.shade.Smart()
	private final prog_update	= kri.shade.Smart()
	
	public final behos	= List[of Behavior]()
	public final total	as uint
	private parTotal	as kri.shade.par.Value[of single]	= null
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	public def constructor(num as uint):
		total = num

	private def collect(type as string, method as string, inter as string, oper as string) as kri.shade.Object:
		names = [b.getMethod(method+'_') for b in behos]
		decl = join("${type} ${n};\n"	for n in names)
		body = join("${oper}\n\t${n}"	for n in names)
		all = "#version 130\n${decl}\n${type} ${method}()\t{${inter}${body};\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)
			
		
	public def init(pc as Context) as void:
		parTotal = pc.pTotal
		sl = kri.Ant.Inst.slotParticles
		def id2out(id as int) as string:
			return 'to_' + sl.Name[id]
		data.semantics.Clear()
		data.semantics.Add( kri.vb.attr.Info(
			slot:pc.at_sys, size:2,
			type:VertexAttribPointerType.Float ))

		sh_init = collect('void', 'init', '', ';')
		sh_reset = collect('void', 'reset', '', ';')
		sh_update = collect('float', 'update', 'return 1.0', '*')
		out_names = List[of string]()
		out_names.Add( id2out( pc.at_sys ) )
		for b in behos:
			for at in b.semantics:
				out_names.Add( id2out(at.slot) )
				data.semantics.Add( at )
			sh = kri.shade.Object( ShaderType.VertexShader, 'beh', b.code )
			prog_init.add(sh)
			prog_update.add(sh)
		
		va.bind()	# has to be after behaviors
		data.initAll(total)
		
		prog_init.add('quat')
		prog_init.add( sh_init, pc.v_init )
		tf.setup(prog_init, false, *out_names.ToArray())
		#prog_init.setGeometry(total)
		prog_init	.link(sl, pc.dict, kri.Ant.Inst.dict)
		
		assert pc.sh_born
		prog_update.add('quat')
		prog_update.add( sh_reset, sh_update, pc.sh_root, pc.sh_born )
		tf.setup(prog_update, false, *out_names.ToArray())
		prog_update	.link(sl, pc.dict, kri.Ant.Inst.dict)
	
	private def process(pe as Emitter, prog as kri.shade.Program) as void:
		return if	not pe.obj
		kri.Ant.Inst.params.modelView.activate( pe.obj.node )
		va.bind()
		tf.bind( pe.data )
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		prog.use()
		using kri.Discarder(),tf.catch():
			GL.DrawArrays( BeginMode.Points, 0, total )
		
	public def reset(pe as Emitter) as void:
		process(pe, prog_init)

	public def tick(pe as Emitter) as void:
		pe.onUpdate()	if pe.onUpdate
		kri.swap(data, pe.data)
		kri.swap(va, pe.va)
		process(pe, prog_update)
