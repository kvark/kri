namespace kri.part

import System
import System.Collections.Generic
import OpenTK.Graphics.OpenGL

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

public class Emitter:
	public visible	as bool		= true
	public size		as single	= 1f
	public onUpdate	as callable() as void
	public final man	as Manager
	public final obj	as kri.Entity
	public final sa		as kri.shade.Smart
	internal data		= kri.vb.Attrib()
	public def constructor(pm as Manager, ent as kri.Entity):
		man,obj = pm,ent
		sa = kri.shade.Smart()
		pm.init(self)
	public def constructor(pe as Emitter):
		man		= pe.man
		obj		= pe.obj
		sa		= pe.sa
		size	= pe.size
		man.init(self)


#---------

public class Context:
	public final	v_init	= kri.shade.Object('/part/init_v')
	public final	g_init	= kri.shade.Object('/part/init_g')
	public final	sh_root	= kri.shade.Object('/part/root_v')
	public sh_born	as kri.shade.Object	= null
	public final	dict	= kri.shade.rep.Dict()
	public final	at_sys	= kri.Ant.Inst.slotParticles.getForced('sys')


#---------

public class Manager:
	private data			= kri.vb.Attrib()
	private final va_init	= kri.vb.Array()
	private final va_draw	= kri.vb.Array()
	private final tf	 	= kri.TransFeedback()
	private final prog_init		= kri.shade.Smart()
	private final prog_update	= kri.shade.Smart()
	private final parTotal	= kri.shade.par.Value[of single]()
	
	public final behos	= List[of Behavior]()
	public final total	as uint
	public Ready as bool:
		get: return prog_init.Ready and prog_update.Ready
	
	private def transform(sa as kri.shade.Smart, generate as bool) as void:
		sa.use()
		using kri.Discarder(),tf.catch():
			if generate: #TODO: use core
				GL.DrawArraysInstanced(	BeginMode.Points, 0, 1, total )
			else:	GL.DrawArrays(		BeginMode.Points, 0, total )


	public def constructor(num as uint):
		total = num

	private def collect(type as string, method as string, inter as string, oper as string) as kri.shade.Object:
		names = [b.getMethod(method+'_') for b in behos]
		decl = join("${type} ${n};\n"	for n in names)
		body = join("${oper}\n\t${n}"	for n in names)
		all = "${kri.Ant.Inst.shaders.header}\n${decl}\n${type} ${method}()\t{${inter}${body};\n}"
		return kri.shade.Object( ShaderType.VertexShader, 'met_'+method, all)
			
		
	public def init(pc as Context) as void:
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
		
		prog_init.add('quat')
		prog_init.add( sh_init, pc.v_init )
		tf.setup(prog_init, false, *out_names.ToArray())
		d = kri.shade.rep.Dict()
		d.add('k_total', parTotal)
		#prog_init.setGeometry(total)
		prog_init.link(sl, d, kri.Ant.Inst.dict)
		
		assert pc.sh_born
		prog_update.add('quat')
		prog_update.add( sh_reset, sh_update, pc.sh_root, pc.sh_born )
		tf.setup(prog_update, false, *out_names.ToArray())
		prog_update.link(sl, pc.dict, kri.Ant.Inst.dict)
		
		va_init.bind()
		data.initUnits(total)
	
	internal def init(pe as Emitter) as void:
		va_init.bind()
		pe.data.semantics.Clear()
		pe.data.semantics.AddRange( data.semantics )
		pe.data.initUnits(total)
		reset(pe)
	
	public def reset(pe as Emitter) as void:
		return if	not pe.obj
		parTotal.Value = (0f, 1f / (total-1))[ total>1 ]
		kri.Ant.Inst.params.modelView.activate( pe.obj.node )
		va_init.bind()
		data.attribFirst()	#sys
		tf.bind( pe.data )
		transform(prog_init,false)
		dr = array[of single](32)
		pe.data.read(dr)
		dr[0] = 0f

	public def tick(pe as Emitter) as void:
		pe.onUpdate()	if pe.onUpdate
		va_draw.bind()
		tf.bind(data)
		src = pe.data
		src.attribAll()
		transform(prog_update,false)
		dr = array[of single](32)
		data.read(dr)	# debug only
		pe.data = data
		data = src
	
	public def draw(pe as Emitter) as void:
		va_draw.bind()
		dr = array[of single](32)
		pe.data.read(dr)
		dr[0] = 0f
		pe.data.attribAll()
		pe.sa.use()
		GL.PointSize( pe.size )
		GL.DrawArrays(BeginMode.Points, 0, total)
